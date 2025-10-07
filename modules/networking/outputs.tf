output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "k3s_cluster_subnet_id" {
  description = "ID of the K3S cluster subnet"
  value       = azurerm_subnet.k3s_cluster_subnet.id
}

output "k3s_cluster_subnet_address_prefix" {
  description = "Address prefix of the K3S cluster subnet"
  value       = azurerm_subnet.k3s_cluster_subnet.address_prefixes[0]
}

output "storage_subnet_id" {
  description = "ID of the storage subnet"
  value       = azurerm_subnet.storage_subnet.id
}


output "storage_subnet_address_prefix" {
  description = "Address prefix of the storage subnet"
  value       = azurerm_subnet.storage_subnet.address_prefixes[0]
}