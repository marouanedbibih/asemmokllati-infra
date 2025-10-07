variable "vm_size" {
  description = "The size of the virtual machine"
  default     = "Standard_B2ms"
}

# Public IP for Master Load Balancer (for ingress traffic)
resource "azurerm_public_ip" "master_lb_public_ip" {
  name                = "k3s-master-lb-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.tags, { "Purpose" = "ingress-traffic" })
}

# Load Balancer for Master Nodes
resource "azurerm_lb" "master_lb" {
  name                = "k3s-master-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "master-lb-frontend"
    public_ip_address_id = azurerm_public_ip.master_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "master_lb_backend_1" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "master-backend-pool-1"
}

resource "azurerm_lb_backend_address_pool" "master_lb_backend_2" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "master-backend-pool-2"
}

resource "azurerm_lb_backend_address_pool" "master_lb_backend_3" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "master-backend-pool-3"
}

# Load Balancer Rules for HTTP (80)
resource "azurerm_lb_rule" "master_lb_http" {
  loadbalancer_id                = azurerm_lb.master_lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "master-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.master_lb_backend_1.id]
  probe_id                       = azurerm_lb_probe.master_lb_http_probe.id
  enable_floating_ip             = false
}

# Load Balancer Rules for HTTPS (443)
resource "azurerm_lb_rule" "master_lb_https" {
  loadbalancer_id                = azurerm_lb.master_lb.id
  name                           = "HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "master-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.master_lb_backend_1.id]
  probe_id                       = azurerm_lb_probe.master_lb_https_probe.id
  enable_floating_ip             = false
}

# Health Probes for HTTP
resource "azurerm_lb_probe" "master_lb_http_probe" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "http-probe"
  port            = 80
  protocol        = "Tcp"
}

# Health Probes for HTTPS
resource "azurerm_lb_probe" "master_lb_https_probe" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "https-probe"
  port            = 443
  protocol        = "Tcp"
}

# Health Probes for SSH
resource "azurerm_lb_probe" "master_lb_ssh_probe" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "ssh-probe"
  port            = 22
  protocol        = "Tcp"
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

# Associate Master NICs with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "master_1_lb_association" {
  network_interface_id    = azurerm_network_interface.master_1_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.master_lb_backend_1.id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_2_lb_association" {
  network_interface_id    = azurerm_network_interface.master_2_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.master_lb_backend_2.id
}

resource "azurerm_network_interface_backend_address_pool_association" "master_3_lb_association" {
  network_interface_id    = azurerm_network_interface.master_3_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.master_lb_backend_3.id
}

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
    k3s_token     = var.k3s_token
    k3s_version   = var.k3s_version
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
    k3s_token      = var.k3s_token
    k3s_version    = var.k3s_version
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
    admin_username        = var.admin_username
    admin_password        = var.admin_password
    k3s_token            = var.k3s_token
    k3s_version          = var.k3s_version
    FIRST_MASTER_IP      = azurerm_network_interface.master_1_nic.private_ip_address
    LOAD_BALANCER_IP     = azurerm_public_ip.master_lb_public_ip.ip_address
    ARGOCD_PASSWORD      = var.argocd_admin_password
  }))

  depends_on = [azurerm_linux_virtual_machine.k3s_master_2]
}