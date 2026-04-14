# ArgoCD 遷移計畫 (GitOps)

## 目標 (Objective)
將專案部署架構轉換為基於 ArgoCD 的 GitOps 模式，主要使用現有的 Helm Chart 作為部署來源，並結合 CI 流程自動更新容器映像檔版本。另外，準備將此架構部署至 GCP 測試。

## 範圍與影響 (Scope & Impact)
- 移除 `terraform/main.tf` 中舊有的 `kubectl apply -k` Kustomize 部署邏輯，因為未來將由 ArgoCD 接管應用程式部署。
- 更新 PR (`feature/argocd-migration`) 以包含上述修正。
- 提供 GCP 環境登入與部署的指令，讓開發者在本地能夠手動測試。

## 影響的檔案 (Key Files & Context)
- `terraform/main.tf` (目標修改檔案：移除 `apply_deployment` 資源，並修正 `wait_conditions` 相依性)

## 實作步驟 (Implementation Steps)
1. **移除舊部署資源**: 刪除 `terraform/main.tf` 裡的 `resource "null_resource" "apply_deployment"`。
2. **修正相依性**: 修正 `wait_conditions`，移除對 `apply_deployment` 的依賴，改為依賴 `module.gcloud` 或是剛建好的 `helm_release.argocd`。
3. **Commit & Push**: 建立 commit 並 push 到 `feature/argocd-migration` 分支，更新 PR。
4. **提供 GCP 部署指令**: 在對話中提供 `gcloud auth login` 及 `terraform apply` 的教學指令。

## 驗證與測試 (Verification & Testing)
1. 在 GCP 上執行 `terraform apply` 時，確認 Terraform 只建置 Cluster 與 ArgoCD，不會自動執行原本的 Kustomize 部署。
2. 應用程式部署透過手動 Apply `argocd/applicationset.yaml` 來驗證。
