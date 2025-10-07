variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "asemmokllati-k3s-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "k3s_cluster_subnet_name" {
  description = "Name of the K3S cluster subnet"
  type        = string
  default     = "k3s-cluster-subnet"
}

variable "k3s_cluster_subnet_address_prefix" {
  description = "Address prefix for the K3S cluster subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "storage_subnet_name" {
  description = "Name of the storage subnet"
  type        = string
  default     = "storage-subnet"
}

variable "storage_subnet_address_prefix" {
  description = "Address prefix for the storage subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
