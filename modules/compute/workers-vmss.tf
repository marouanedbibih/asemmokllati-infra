# # Public IP for NAT Gateway (for VMSS outbound internet access)
# resource "azurerm_public_ip" "natgw_pip" {
#   name                = "k3s-natgw-pip"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   tags                = merge(var.tags, { "Component" = "nat-gateway" })
# }

# # NAT Gateway for VMSS outbound internet access
# resource "azurerm_nat_gateway" "k3s_natgw" {
#   name                = "k3s-natgw"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku_name            = "Standard"
#   tags                = merge(var.tags, { "Component" = "nat-gateway" })
# }

# # Associate Public IP with NAT Gateway
# resource "azurerm_nat_gateway_public_ip_association" "natgw_pip_assoc" {
#   nat_gateway_id       = azurerm_nat_gateway.k3s_natgw.id
#   public_ip_address_id = azurerm_public_ip.natgw_pip.id
# }

# # Shared Load Balancer Public IP for VMSS
# resource "azurerm_public_ip" "vmss_lb_public_ip" {
#   name                = "k3s-vmss-lb-public-ip"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   tags                = merge(var.tags, { "Component" = "vmss-loadbalancer" })
# }

# # Shared Load Balancer for VMSS
# resource "azurerm_lb" "vmss_lb" {
#   name                = "k3s-vmss-lb"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku                 = "Standard"
#   tags                = merge(var.tags, { "Component" = "vmss-loadbalancer" })

#   frontend_ip_configuration {
#     name                 = "vmss-frontend"
#     public_ip_address_id = azurerm_public_ip.vmss_lb_public_ip.id
#   }
# }



# # Backend Address Pool for Dev Environment
# resource "azurerm_lb_backend_address_pool" "dev_backend_pool" {
#   loadbalancer_id = azurerm_lb.vmss_lb.id
#   name            = "dev-backend-pool"
# }

# # Backend Address Pool for Prod Environment
# resource "azurerm_lb_backend_address_pool" "prod_backend_pool" {
#   loadbalancer_id = azurerm_lb.vmss_lb.id
#   name            = "prod-backend-pool"
# }

# # Health Probe for SSH
# resource "azurerm_lb_probe" "ssh_probe" {
#   loadbalancer_id = azurerm_lb.vmss_lb.id
#   name            = "ssh-health-probe"
#   port            = 22
#   protocol        = "Tcp"
# }

# # SSH NAT Rules for Dev Environment (ports 2200-2209)
# resource "azurerm_lb_nat_pool" "dev_ssh_nat_pool" {
#   resource_group_name            = var.resource_group_name
#   loadbalancer_id                = azurerm_lb.vmss_lb.id
#   name                           = "dev-ssh-nat-pool"
#   protocol                       = "Tcp"
#   frontend_port_start            = 2200
#   frontend_port_end              = 2209
#   backend_port                   = 22
#   frontend_ip_configuration_name = "vmss-frontend"
# }

# # SSH NAT Rules for Prod Environment (ports 2210-2219)  
# resource "azurerm_lb_nat_pool" "prod_ssh_nat_pool" {
#   resource_group_name            = var.resource_group_name
#   loadbalancer_id                = azurerm_lb.vmss_lb.id
#   name                           = "prod-ssh-nat-pool"
#   protocol                       = "Tcp"
#   frontend_port_start            = 2210
#   frontend_port_end              = 2219
#   backend_port                   = 22
#   frontend_ip_configuration_name = "vmss-frontend"
# }

# # VM Scale Set for Dev Environment
# resource "azurerm_linux_virtual_machine_scale_set" "dev_vmss" {
#   depends_on = [azurerm_linux_virtual_machine.k3s_master]
#   name                = "k3s-dev-vmss"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   sku                 = var.dev_vm_size != null ? var.dev_vm_size : "Standard_B1s"
#   instances           = var.dev_min_instances
#   admin_username      = var.admin_username

#   disable_password_authentication = false
#   admin_password                  = var.admin_password

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching              = "ReadWrite"
#   }

#   admin_ssh_key {
#     username   = var.admin_username
#     public_key = file(var.ssh_public_key_path)
#   }

#   network_interface {
#     name    = "dev-vmss-nic"
#     primary = true

#     ip_configuration {
#       name                                   = "internal"
#       primary                                = true
#       subnet_id                              = var.k3s_cluster_subnet_id
#       load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.dev_backend_pool.id]
#       load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.dev_ssh_nat_pool.id]
#     }
#   }

#   # K3S worker node installation script
#   custom_data = base64encode(templatefile("${path.module}/scripts/init-worker.sh", {
#     k3s_version    = var.k3s_version
#     k3s_token      = var.k3s_token
#     master_ip      = azurerm_network_interface.master_nic.private_ip_address
#     environment    = "dev"
#     admin_username = var.admin_username
#   }))

#   tags = merge(var.tags, {
#     "Role"          = "worker",
#     "Environment"   = "dev",
#     "K3S-Node-Type" = "agent"
#   })
# }

# # VM Scale Set for Prod Environment
# resource "azurerm_linux_virtual_machine_scale_set" "prod_vmss" {
#   depends_on = [azurerm_linux_virtual_machine.k3s_master]
#   name                = "k3s-prod-vmss"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   sku                 = var.prod_vm_size != null ? var.prod_vm_size : "Standard_B1ms"
#   instances           = var.prod_min_instances
#   admin_username      = var.admin_username

#   disable_password_authentication = false
#   admin_password                  = var.admin_password

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

#   os_disk {
#     storage_account_type = "Premium_LRS"
#     caching              = "ReadWrite"
#   }

#   admin_ssh_key {
#     username   = var.admin_username
#     public_key = file(var.ssh_public_key_path)
#   }

#   network_interface {
#     name    = "prod-vmss-nic"
#     primary = true

#     ip_configuration {
#       name                                   = "internal"
#       primary                                = true
#       subnet_id                              = var.k3s_cluster_subnet_id
#       load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.prod_backend_pool.id]
#       load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.prod_ssh_nat_pool.id]
#     }
#   }

#   # K3S worker node installation script
#   custom_data = base64encode(templatefile("${path.module}/scripts/init-worker.sh", {
#     k3s_version    = var.k3s_version
#     k3s_token      = var.k3s_token
#     master_ip      = azurerm_network_interface.master_nic.private_ip_address
#     environment    = "prod"
#     admin_username = var.admin_username
#   }))

#   tags = merge(var.tags, {
#     "Role"          = "worker",
#     "Environment"   = "prod",
#     "K3S-Node-Type" = "agent"
#   })
# }

# # Auto-scaling for Dev Environment
# resource "azurerm_monitor_autoscale_setting" "dev_autoscale" {
#   name                = "k3s-dev-autoscale"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   target_resource_id  = azurerm_linux_virtual_machine_scale_set.dev_vmss.id

#   profile {
#     name = "defaultProfile"

#     capacity {
#       default = var.dev_min_instances
#       minimum = var.dev_min_instances
#       maximum = var.dev_max_instances
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.dev_vmss.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = 70
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.dev_vmss.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = 30
#       }

#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT10M"
#       }
#     }
#   }

#   depends_on = [azurerm_linux_virtual_machine_scale_set.dev_vmss]

#   tags = var.tags
# }

# # Auto-scaling for Prod Environment
# resource "azurerm_monitor_autoscale_setting" "prod_autoscale" {
#   name                = "k3s-prod-autoscale"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   target_resource_id  = azurerm_linux_virtual_machine_scale_set.prod_vmss.id

#   profile {
#     name = "defaultProfile"

#     capacity {
#       default = var.prod_min_instances
#       minimum = var.prod_min_instances
#       maximum = var.prod_max_instances
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.prod_vmss.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = 75
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.prod_vmss.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = 25
#       }

#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT15M"
#       }
#     }
#   }

#   depends_on = [azurerm_linux_virtual_machine_scale_set.prod_vmss]

#   tags = var.tags
# }



# # Network Security Group for Load Balancer
# resource "azurerm_network_security_group" "lb_nsg" {
#   name                = "k3s-lb-nsg"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   # Allow SSH NAT Pool ports for Dev (2200-2209)
#   security_rule {
#     name                       = "SSH-Dev-NAT"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "2200-2209"
#     source_address_prefix      = "Internet"
#     destination_address_prefix = "*"
#   }

#   # Allow SSH NAT Pool ports for Prod (2210-2219)
#   security_rule {
#     name                       = "SSH-Prod-NAT"
#     priority                   = 1002
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "2210-2219"
#     source_address_prefix      = "Internet"
#     destination_address_prefix = "*"
#   }

#   # Allow HTTP for applications
#   security_rule {
#     name                       = "HTTP"
#     priority                   = 1003
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "Internet"
#     destination_address_prefix = "*"
#   }

#   # Allow HTTPS for applications
#   security_rule {
#     name                       = "HTTPS"
#     priority                   = 1004
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     source_address_prefix      = "Internet"
#     destination_address_prefix = "*"
#   }

#   tags = merge(var.tags, { "Component" = "loadbalancer-security" })
# }

# # Associate NAT Gateway with K3s cluster subnet
# resource "azurerm_subnet_nat_gateway_association" "k3s_natgw_assoc" {
#   subnet_id      = var.k3s_cluster_subnet_id
#   nat_gateway_id = azurerm_nat_gateway.k3s_natgw.id
# }


