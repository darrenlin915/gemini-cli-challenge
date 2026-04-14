resource "google_cloudbuild_trigger" "pr_trigger" {
  name        = "pr-to-main-trigger"
  description = "Builds images on PR to main branch"

  github {
    owner = var.github_owner
    name  = var.github_repo
    pull_request {
      branch = "^main$"
    }
  }

  filename = "cloudbuild-pr.yaml"

  depends_on = [
    module.enable_google_apis
  ]
}
