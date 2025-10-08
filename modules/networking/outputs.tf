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

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = azurerm_public_ip.nat_gateway_public_ip.ip_address
}

output "master_lb_id" {
  description = "ID of the master load balancer"
  value       = azurerm_lb.master_lb.id
}

output "master_lb_public_ip" {
  description = "Public IP address of the master load balancer"
  value       = azurerm_public_ip.master_lb_public_ip.ip_address
}

output "master_lb_backend_pool_1_id" {
  description = "ID of the master load balancer backend pool 1"
  value       = azurerm_lb_backend_address_pool.master_lb_backend_1.id
}

output "master_lb_backend_pool_2_id" {
  description = "ID of the master load balancer backend pool 2"
  value       = azurerm_lb_backend_address_pool.master_lb_backend_2.id
}

output "master_lb_backend_pool_3_id" {
  description = "ID of the master load balancer backend pool 3"
  value       = azurerm_lb_backend_address_pool.master_lb_backend_3.id
}

output "master_lb_fqdn" {
  description = "FQDN of the master load balancer"
  value       = azurerm_public_ip.master_lb_public_ip.fqdn
}

output "ingress_endpoints" {
  description = "Ingress endpoints information"
  value = {
    load_balancer_ip = azurerm_public_ip.master_lb_public_ip.ip_address
    http_port       = 80
    https_port      = 443
    dns_setup_info  = "Point your domain A record to: ${azurerm_public_ip.master_lb_public_ip.ip_address}"
  }
}

# SSH NAT Rules outputs
output "ssh_master_1_nat_rule_id" {
  description = "ID of the SSH NAT rule for master 1"
  value       = azurerm_lb_nat_rule.ssh_master_1.id
}

output "ssh_master_2_nat_rule_id" {
  description = "ID of the SSH NAT rule for master 2"
  value       = azurerm_lb_nat_rule.ssh_master_2.id
}

output "ssh_master_3_nat_rule_id" {
  description = "ID of the SSH NAT rule for master 3"
  value       = azurerm_lb_nat_rule.ssh_master_3.id
}