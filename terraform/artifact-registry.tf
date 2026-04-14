resource "google_artifact_registry_repository" "microservices_demo" {
  location      = var.region
  repository_id = "microservices-demo"
  format        = "DOCKER"
  project       = var.gcp_project_id

  depends_on = [module.enable_google_apis]
}
