
output "azure_subscription_id" {
  description = "Azure Subscription ID (Sensitive)"
  value       = var.azure_subscription_id
  sensitive   = true
}

output "azure_tenant_id" {
  description = "Azure Tenant ID (Sensitive)"
  value       = var.azure_tenant_id
  sensitive   = true
}

output "azure_client_id" {
  description = "Azure Client ID (Sensitive)"
  value       = var.azure_client_id
  sensitive   = true
}

output "azure_client_secret" {
  description = "Azure Client Secret (Sensitive)"
  value       = var.azure_client_secret
  sensitive   = true
}

output "grafana_admin_password" {
  description = "Grafana admin password (Sensitive)"
  value       = var.grafana_admin_password
  sensitive   = true
}
