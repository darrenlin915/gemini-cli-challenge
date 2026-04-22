# ArgoCD 部署指南 (GKE + 多環境架構)

## 1. 使用 Terraform 自動安裝 ArgoCD
我們已經將 ArgoCD 的安裝過程整合到了 Terraform 中。當你部署基礎設施時，Terraform 會利用 Helm Provider 自動在 GKE 叢集上安裝 ArgoCD。

切換到 `terraform/` 目錄並執行部署：
```bash
cd terraform/
terraform init
terraform apply
```
*這會在你的叢集上建立 `argocd` Namespace 並部署 ArgoCD 服務。*

## 2. 登入 ArgoCD UI
基礎設施部署完成後，需要使用 `kubectl` 連線到你的 GKE 叢集，接著可以使用 Port-forward 方式登入：
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
帳號為 `admin`，初始密碼可以透過以下指令取得：
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

## 3. 部署 ApplicationSet (多環境管理)
本專案使用 `ApplicationSet` 來統一管理多個環境 (`dev`, `staging`, `prod`)。
這個 ApplicationSet 會去讀取 Repo 中 `helm-chart/` 目錄下的基礎 Helm chart，並根據不同環境載入 `environments/<env>/values.yaml` 中的設定檔來覆蓋預設值。

執行以下指令部署 ApplicationSet：
```bash
kubectl apply -n argocd -f argocd/applicationset.yaml
```

## 4. 目錄架構說明
- `terraform/argocd.tf`: 定義 ArgoCD 的基礎安裝 (Helm Release)。
- `helm-chart/`: 共用的應用程式基礎 Helm Chart。
- `environments/`: 存放各個環境專屬的 Helm Values 覆蓋設定：
  - `environments/dev/values.yaml`
  - `environments/staging/values.yaml`
  - `environments/prod/values.yaml`
- `argocd/applicationset.yaml`: 定義 ArgoCD 如何讀取各個環境並自動生成對應的 `Application`。

## 5. CI 更新流程 (GitOps)
未來在 CI Pipeline (例如 GitHub Actions) 建立好新的容器映像檔 (Image) 後，可以透過自動化腳本將新的 Image Tag 寫入對應環境的 `environments/<env>/values.yaml` 中，然後由 CI Bot 自動 Commit 並 Push 回這個 Git Repository。ArgoCD 將會自動偵測到這些 Git commit 變更，並同步發佈新版本到 Kubernetes。

## 6. Promotion flow: dev → staging → prod

The CI/CD pipeline gates promotion between environments to avoid every merge
deploying straight to production.

**Auto-deploy to dev (on merge to `main`)**
- `.github/workflows/ci-main.yaml` detects which services changed in the merge
  commit, writes the new short SHA into `environments/dev/values.yaml` only,
  and pushes the update back to `main` with `[skip ci]`.
- ArgoCD's `dev-onlineboutique` application picks up the change and syncs.
- `staging` and `prod` values files are **not** touched.

**Manual promotion to staging / prod**
1. Verify `dev-onlineboutique` (or `staging-onlineboutique`) is **Healthy**
   and **Synced** in ArgoCD and any smoke tests pass.
2. From the GitHub Actions tab, run the **Promote** workflow with:
   - `from = dev`, `to = staging`, **or**
   - `from = staging`, `to = prod`.
   (Only these two paths are accepted; skipping or reversing is rejected.)
3. The workflow opens a PR titled `Promote <from> → <to>` containing only the
   diff to `environments/<to>/values.yaml`.
4. A code owner reviews and merges. ArgoCD then syncs the target environment.

**Why this design:** copying tags between env files (rather than auto-bumping
all envs) keeps prod behind a human checkpoint while still being a single-repo
GitOps setup. The PR is the gate, not the workflow run, so review is auditable
in the normal GitHub flow.
