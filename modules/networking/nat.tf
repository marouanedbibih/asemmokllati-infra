# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  name                = "${var.resource_group_name}-nat-gateway-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# NAT Gateway for outbound internet access
resource "azurerm_nat_gateway" "main" {
  name                    = "${var.resource_group_name}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_public_ip.id
}

# Associate NAT Gateway with K3S Cluster Subnet
resource "azurerm_subnet_nat_gateway_association" "k3s_cluster" {
  subnet_id      = azurerm_subnet.k3s_cluster_subnet.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
