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

# Github Configuration
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repository in the format 'owner/repo'"
  type        = string
  default     = "yourusername/your-repo"
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}
