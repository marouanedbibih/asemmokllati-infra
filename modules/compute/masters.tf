variable "vm_size" {
  description = "The size of the virtual machine"
  default     = "Standard_B2ms"
}

# Network Interfaces for Master Nodes
resource "azurerm_network_interface" "master_1_nic" {
  name                = "k3s-master-1-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.k3s_cluster_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

resource "azurerm_network_interface" "master_2_nic" {
  name                = "k3s-master-2-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.k3s_cluster_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.11"
  }
}

resource "azurerm_network_interface" "master_3_nic" {
  name                = "k3s-master-3-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.k3s_cluster_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.12"
  }
}

# Note: Backend address pool associations will be configured via main.tf
# using the load balancer backend pool IDs from the networking module

# K3S Master 1 Virtual Machine (Cluster Initializer)
resource "azurerm_linux_virtual_machine" "k3s_master_1" {
  name                = "master-vm-1"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.master_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = merge(var.tags, { 
    "Role" = "master", 
    "K3S-Node-Type" = "server",
    "Master-Index" = "1"
  })

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.master_1_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/master-init-m1.sh", {
    admin_username = var.admin_username
    admin_password = var.admin_password
    k3s_token      = var.k3s_token
    k3s_version    = var.k3s_version
  }))
}

# K3S Master 2 Virtual Machine (Joins cluster)
resource "azurerm_linux_virtual_machine" "k3s_master_2" {
  name                = "master-vm-2"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.master_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = merge(var.tags, { 
    "Role" = "master", 
    "K3S-Node-Type" = "server",
    "Master-Index" = "2"
  })

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.master_2_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/master-init-m2.sh", {
    admin_username  = var.admin_username
    admin_password  = var.admin_password
    k3s_token       = var.k3s_token
    k3s_version     = var.k3s_version
    FIRST_MASTER_IP = azurerm_network_interface.master_1_nic.private_ip_address
  }))

  depends_on = [azurerm_linux_virtual_machine.k3s_master_1]
}

# K3S Master 3 Virtual Machine (Joins cluster and installs ArgoCD)
resource "azurerm_linux_virtual_machine" "k3s_master_3" {
  name                = "master-vm-3"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.master_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = merge(var.tags, { 
    "Role" = "master", 
    "K3S-Node-Type" = "server",
    "Master-Index" = "3"
  })

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.master_3_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/master-init-m3.sh", {
    admin_username   = var.admin_username
    admin_password   = var.admin_password
    k3s_token        = var.k3s_token
    k3s_version      = var.k3s_version
    FIRST_MASTER_IP  = azurerm_network_interface.master_1_nic.private_ip_address
    LOAD_BALANCER_IP = var.master_lb_public_ip
    ARGOCD_PASSWORD  = var.argocd_admin_password
  }))

  depends_on = [azurerm_linux_virtual_machine.k3s_master_2]
}

resource "azurerm_network_interface_backend_address_pool_association" "master_1_lb_association" {
  network_interface_id    = azurerm_network_interface.master_1_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.master_lb_backend_pool_1_id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_2_lb_association" {
  network_interface_id    = azurerm_network_interface.master_2_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.master_lb_backend_pool_2_id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_3_lb_association" {
  network_interface_id    = azurerm_network_interface.master_3_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.master_lb_backend_pool_3_id
}

# NAT Rule Associations for SSH access
resource "azurerm_network_interface_nat_rule_association" "master_1_ssh_nat" {
  network_interface_id  = azurerm_network_interface.master_1_nic.id
  ip_configuration_name = "internal"
  nat_rule_id          = var.ssh_master_1_nat_rule_id
}

resource "azurerm_network_interface_nat_rule_association" "master_2_ssh_nat" {
  network_interface_id  = azurerm_network_interface.master_2_nic.id
  ip_configuration_name = "internal"
  nat_rule_id          = var.ssh_master_2_nat_rule_id
}

resource "azurerm_network_interface_nat_rule_association" "master_3_ssh_nat" {
  network_interface_id  = azurerm_network_interface.master_3_nic.id
  ip_configuration_name = "internal"
  nat_rule_id          = var.ssh_master_3_nat_rule_id
}