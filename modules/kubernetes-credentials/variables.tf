# Variables for kubernetes-credentials module

variable "master_public_ip" {
  description = "The public IP address of the K3s master node"
  type        = string
}

variable "admin_username" {
  description = "The admin username for SSH access to the master node"
  type        = string
  default     = "azureuser"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key for accessing the master node"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "kubeconfig_output_path" {
  description = "Path where to save the kubeconfig file"
  type        = string
  default     = "./kubeconfig"
}