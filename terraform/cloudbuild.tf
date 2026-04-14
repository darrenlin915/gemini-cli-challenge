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

resource "google_cloudbuild_trigger" "main_push_trigger" {
  name        = "main-push-cd-trigger"
  description = "Builds and pushes images on merge to main, updates Helm values for GitOps"

  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = "^main$"
    }
  }

  # Don't re-trigger when the pipeline updates environment values
  ignored_files = ["environments/**"]

  filename = "cloudbuild.yaml"

  depends_on = [
    module.enable_google_apis
  ]
}
