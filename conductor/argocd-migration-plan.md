# ArgoCD 遷移計畫

## 目標 (Objective)
將專案部署架構轉換為基於 ArgoCD 的 GitOps 模式，主要使用現有的 Helm Chart 作為部署來源，並結合 CI 流程自動更新容器映像檔版本。

## 範圍與影響 (Scope & Impact)
- 新增 `argocd/` 目錄，存放 ArgoCD 專屬的 `Application` 設定檔。
- 修改 CI 流程（如 GitHub Actions），使其在建置新的 Container Image 後，自動修改對應的設定檔。
- 將變更透過 CI 自動 Commit 回 Git Repository。
- 提供 ArgoCD 部署的相關文件。

## 影響的檔案 (Key Files & Context)
- `argocd/application.yaml` (新增：定義 ArgoCD Application，指向本 Repo 的 Helm Chart)
- `.github/workflows/ci-main.yaml` (或新增專屬 workflow：加入修改 Tag 與 Commit/Push 的步驟)
- `helm-chart/values.yaml` (目標修改檔案：更新 Image Tag)
- `docs/argocd-setup.md` (新增文件：說明如何安裝 ArgoCD 及部署此應用)

## 實作步驟 (Implementation Steps)
1. **建立 ArgoCD Application 部署檔**: 
   - 撰寫 `argocd/application.yaml`，指定 ArgoCD 監聽本專案 Repo 的 `helm-chart/` 目錄，並將應用程式部署到指定的 Kubernetes Namespace。
2. **調整 CI 流程，自動更新 Image Tag**: 
   - 在 `.github/workflows/` 中（例如 `ci-main.yaml` 內），於 Docker build & push 完成後加入自動化腳本步驟。
   - 該步驟會讀取剛建置好的 Image tags，並使用工具（如 `yq` 或 `sed`）自動修改 `helm-chart/values.yaml` 中對應的 image tag 欄位。
3. **設定自動 Commit 與 Push (GitOps Workflow)**: 
   - 在 CI 的最後階段，使用 git 指令（設定 bot 身份）將上述變更 add、commit，並 push 回 main 分支（或特定發布分支）。
4. **撰寫文件**: 
   - 建立 `docs/argocd-setup.md`，提供快速套用 `argocd/application.yaml` 的指令與除錯指南。

## 驗證與測試 (Verification & Testing)
1. **本機或測試叢集驗證**: 在 Kubernetes 測試環境上安裝 ArgoCD，手動 apply `argocd/application.yaml`，確認 Helm chart 能夠被正確渲染與部署。
2. **CI 流程整合測試**: 觸發一次程式碼變更並推送到 Repo，觀察 GitHub Actions 是否成功建立 Image、更新 `values.yaml`，且沒有發生存取權限問題。
3. **ArgoCD 同步測試**: 觀察在 CI 完成推播後，ArgoCD 是否能偵測到 Git commit 的變化，並自動 (或手動觸發) 同步新的資源狀態。