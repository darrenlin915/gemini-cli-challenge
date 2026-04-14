# Existing Cloud Build v2 GitHub connection (import with terraform import)
resource "google_cloudbuildv2_connection" "github" {
  project  = var.gcp_project_id
  location = var.region
  name     = "demo"

  github_config {
    app_installation_id = 76245483
    authorizer_credential {
      oauth_token_secret_version = "projects/ai-for-sre-demo/secrets/demo-github-oauthtoken-a94e28/versions/latest"
    }
  }
}

# Link the GitHub repository to the connection
resource "google_cloudbuildv2_repository" "repo" {
  project           = var.gcp_project_id
  location          = var.region
  name              = var.github_repo
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}

# CI: Build images on PR to main
resource "google_cloudbuild_trigger" "pr_trigger" {
  project     = var.gcp_project_id
  location    = var.region
  name        = "pr-to-main-trigger"
  description = "Builds images on PR to main branch"

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id
    pull_request {
      branch = "^main$"
    }
  }

  filename        = "cloudbuild-pr.yaml"
  service_account = "projects/${var.gcp_project_id}/serviceAccounts/636965397022@cloudbuild.gserviceaccount.com"

  depends_on = [
    module.enable_google_apis
  ]
}

# CD: Build, push, and update Helm values on merge to main
resource "google_cloudbuild_trigger" "main_push_trigger" {
  project     = var.gcp_project_id
  location    = var.region
  name        = "main-push-cd-trigger"
  description = "Builds and pushes images on merge to main, updates Helm values for GitOps"

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id
    push {
      branch = "^main$"
    }
  }

  # Don't re-trigger when the pipeline updates environment values
  ignored_files = ["environments/**"]

  filename        = "cloudbuild.yaml"
  service_account = "projects/${var.gcp_project_id}/serviceAccounts/636965397022@cloudbuild.gserviceaccount.com"

  depends_on = [
    module.enable_google_apis
  ]
}
