variable "k3s_api_server_url" {
  description = "The URL of the K3s API server"
  type        = string
}

variable "k3s_token" {
  description = "The token for the K3s API server"
  type        = string
}


variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "./kubeconfig"
}

variable "k3s_cluster_ready" {
  description = "Signal that K3s cluster is ready"
  type        = bool
  default     = true
}

variable "enable_argocd" {
  description = "Enable ArgoCD installation"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus + Grafana)"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}
variable "master_public_ip" {
  description = "Public IP address of the master node"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate registration"
  type        = string
  default     = "admin@example.com"
}

variable "admin_username" {
  description = "Admin username for SSH access"
  type        = string
  default     = "azureuser"
}

variable "grafana_admin_username" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "domain_name" {
  description = "Domain name for ingress hostnames"
  type        = string
  default     = "marouanedbibih.studio"
}


# Rancher Configuration
variable "rancher_admin_username" {
  description = "Rancher admin username"
  type        = string
  default     = "admin"
}

variable "rancher_admin_password" {
  description = "Rancher admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
}
