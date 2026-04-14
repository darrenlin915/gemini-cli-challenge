# Deploy ArgoCD using Helm provider

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  
  # Wait until ArgoCD pods are ready before finishing Terraform apply
  wait = true

  depends_on = [
    google_container_cluster.my_cluster,
    google_container_node_pool.primary
  ]
}
