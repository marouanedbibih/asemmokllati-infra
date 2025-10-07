variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment" {
  description = "Environment for the deployment"
  type        = string
  default     = "development"
}

variable "master_vm_size" {
  description = "Size of the master VM"
  type        = string
  default     = "Standard_B6s"
}
variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "k3s_cluster_subnet_id" {
  description = "ID of the K3S cluster subnet"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "k3s_token" {
  description = "K3S cluster join token"
  type        = string
  sensitive   = true
}

variable "k3s_version" {
  description = "K3S version to install"
  type        = string
  default     = "latest"
}

variable "enable_k3s_dashboard" {
  description = "Enable Kubernetes dashboard"
  type        = bool
  default     = false
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}


# VM Scale Set Configuration Variables
variable "dev_vm_size" {
  description = "Size of the development VM instances in VMSS"
  type        = string
  default     = "Standard_B2s"  # 2 vCPU, 4 GB RAM
}

variable "prod_vm_size" {
  description = "Size of the production VM instances in VMSS"
  type        = string
  default     = "Standard_B2ms"  # 2 vCPU, 8 GB RAM
}

variable "dev_min_instances" {
  description = "Minimum number of instances in dev VMSS"
  type        = number
  default     = 2
}

variable "dev_max_instances" {
  description = "Maximum number of instances in dev VMSS"
  type        = number
  default     = 4  # Increased for better scaling
}

variable "prod_min_instances" {
  description = "Minimum number of instances in prod VMSS"
  type        = number
  default     = 2  # Required for autoscaling
}

variable "prod_max_instances" {
  description = "Maximum number of instances in prod VMSS"
  type        = number
  default     = 5  # Better production scaling
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
  sensitive   = true
}