variable "k3s_token" {
  description = "K3S cluster join token"
  type        = string
}


# ArgoCD Configuration
variable "argocd_admin_username" {
  description = "ArgoCD admin username"
  type        = string
  default     = "admin"
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  default     = "argocd123!"
  sensitive   = true
}


variable "domain_name" {
  description = "Domain name for ingress hostnames (leave empty for .local)"
  type        = string
  default     = "marouanedbibih.studio"
}



# Azure Service Principal Credentials (Sensitive)
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "enable_bitnami_monitoring" {
  description = "Enable Bitnami monitoring"
  type        = bool
  default     = false
}


# Azure Cloud Virtual Machines
variable "admin_username" {
  description = "Admin username for Azure virtual machines"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for Azure virtual machines"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!"
}

# Rancher Configuration
variable "rancher_admin_password" {
  description = "Rancher admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "rancher_admin_username" {
  description = "Rancher admin username"
  type        = string
  default     = "admin"
}

# Grafana Configurations
variable "grafana_admin_password" {
  description = "Grafana admin password for Bitnami monitoring"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "grafana_admin_username" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

# Let’s Encrypt Configuration
variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt registration"
  type        = string
  default     = "admin@yourdomain.com"
}