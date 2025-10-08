variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "k3s_cluster_subnet_id" {
  description = "ID of the K3S cluster subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# variable "key_vault_name" {
#   description = "Name of the Azure Key Vault"
#   type        = string
# }

# variable "tenant_id" {
#   description = "Azure AD tenant ID"
#   type        = string
# }

# variable "admin_object_id" {
#   description = "Object ID of the admin user/service principal for Key Vault access"
#   type        = string
# }