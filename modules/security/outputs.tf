output "k3s_nsg_id" {
  description = "ID of the K3S network security group"
  value       = azurerm_network_security_group.k3s_nsg.id
}

# output "key_vault_id" {
#   description = "ID of the Azure Key Vault"
#   value       = azurerm_key_vault.main_kv.id
# }

# output "key_vault_uri" {
#   description = "URI of the Azure Key Vault"
#   value       = azurerm_key_vault.main_kv.vault_uri
# }