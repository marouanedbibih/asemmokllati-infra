output "k3s_nsg_id" {
  description = "ID of the K3S network security group"
  value       = azurerm_network_security_group.k3s_nsg.id
}

# Azure Key Vault outputs removed