# # Azure Key Vault for storing secrets and keys
# resource "azurerm_key_vault" "main_kv" {
#   name                        = "your-keyvault-name"
#   location                    = var.location
#   resource_group_name         = var.resource_group_name
#   tenant_id                   = "your-azure-tenant-id"
#   sku_name                    = "standard"
#   soft_delete_retention_days  = 7
#   purge_protection_enabled    = false

#   access_policy {
#     tenant_id = var.tenant_id
#     object_id = "your-user-object-id" # Set this to your Azure AD user/service principal object ID
#     secret_permissions = ["get", "list", "set", "delete"]
#     key_permissions    = ["get", "list", "create", "delete"]
#     certificate_permissions = ["get", "list", "create", "delete"]
#   }

#   tags = merge(var.tags, { "Component" = "keyvault" })
# }
