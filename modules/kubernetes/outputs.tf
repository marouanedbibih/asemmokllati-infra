# output "helm_kubeconfig_blob_url" {
#   description = "URL of the Helm kubeconfig blob"
#   value       = azurerm_storage_blob.helm_kubeconfig.url
# }

# output "helm_service_account_token" {
#   description = "Helm service account token"
#   value       = data.kubernetes_secret.helm_token.data.token
#   sensitive   = true
# }

# output "helm_service_account_name" {
#   description = "Name of the Helm service account"
#   value       = kubernetes_service_account.helm_service_account.metadata[0].name
# }

# output "helm_cluster_role_name" {
#   description = "Name of the Helm cluster role"
#   value       = kubernetes_cluster_role.helm_cluster_role.metadata[0].name
# }

# output "helm_releases_status" {
#   description = "Status of deployed Helm releases"
#   value = {
#     nginx_ingress = "Deployed"
#     cert_manager  = "Deployed"
#     argocd        = var.enable_argocd ? "Deployed" : "Disabled"
#     monitoring    = var.enable_monitoring ? "Deployed" : "Disabled"
#   }
# }

# output "ingress_controller_info" {
#   description = "Information about the ingress controller"
#   value = {
#     name      = helm_release.nginx_ingress.name
#     namespace = helm_release.nginx_ingress.namespace
#     version   = helm_release.nginx_ingress.version
#   }
# }

# output "cert_manager_info" {
#   description = "Information about cert-manager"
#   value = {
#     name      = helm_release.cert_manager.name
#     namespace = helm_release.cert_manager.namespace
#     version   = helm_release.cert_manager.version
#   }
# }

# output "argocd_info" {
#   description = "Information about ArgoCD (if enabled)"
#   value = var.enable_argocd ? {
#     name      = helm_release.argocd[0].name
#     namespace = helm_release.argocd[0].namespace
#     version   = helm_release.argocd[0].version
#   } : null
# }

# output "monitoring_info" {
#   description = "Information about monitoring stack (if enabled)"
#   value = var.enable_monitoring ? {
#     name      = helm_release.prometheus[0].name
#     namespace = helm_release.prometheus[0].namespace
#     version   = helm_release.prometheus[0].version
#   } : null
# }
