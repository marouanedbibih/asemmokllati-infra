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

# Backend Address Pools for Master Nodes
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

# Health Probes
resource "azurerm_lb_probe" "master_lb_http_probe" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "http-probe"
  port            = 80
  protocol        = "Tcp"
}

resource "azurerm_lb_probe" "master_lb_https_probe" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "https-probe"
  port            = 443
  protocol        = "Tcp"
}

resource "azurerm_lb_probe" "master_lb_ssh_probe" {
  loadbalancer_id = azurerm_lb.master_lb.id
  name            = "ssh-probe"
  port            = 22
  protocol        = "Tcp"
}

# NAT Rules for SSH access to each master node
resource "azurerm_lb_nat_rule" "ssh_master_1" {
  name                           = "ssh-master-1"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.master_lb.id
  frontend_ip_configuration_name = "master-lb-frontend"
  protocol                       = "Tcp"
  frontend_port                  = 2221
  backend_port                   = 22
}

resource "azurerm_lb_nat_rule" "ssh_master_2" {
  name                           = "ssh-master-2"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.master_lb.id
  frontend_ip_configuration_name = "master-lb-frontend"
  protocol                       = "Tcp"
  frontend_port                  = 2222
  backend_port                   = 22
}

resource "azurerm_lb_nat_rule" "ssh_master_3" {
  name                           = "ssh-master-3"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.master_lb.id
  frontend_ip_configuration_name = "master-lb-frontend"
  protocol                       = "Tcp"
  frontend_port                  = 2223
  backend_port                   = 22
}
