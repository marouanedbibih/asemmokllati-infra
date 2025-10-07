output "master_vm_ids" {
  description = "IDs of the K3S master virtual machines"
  value       = [
    azurerm_linux_virtual_machine.k3s_master_1.id,
    azurerm_linux_virtual_machine.k3s_master_2.id,
    azurerm_linux_virtual_machine.k3s_master_3.id
  ]
}

output "master_private_ips" {
  description = "Private IP addresses of the K3S master nodes"
  value       = [
    azurerm_network_interface.master_1_nic.private_ip_address,
    azurerm_network_interface.master_2_nic.private_ip_address,
    azurerm_network_interface.master_3_nic.private_ip_address
  ]
}

output "first_master_ip" {
  description = "First master node IP for cluster joining"
  value       = azurerm_network_interface.master_1_nic.private_ip_address
}

output "master_vm_names" {
  description = "Names of the K3S master VMs"
  value       = [
    azurerm_linux_virtual_machine.k3s_master_1.name,
    azurerm_linux_virtual_machine.k3s_master_2.name,
    azurerm_linux_virtual_machine.k3s_master_3.name
  ]
}

# Load Balancer Outputs
output "master_lb_public_ip" {
  description = "Public IP address of the master load balancer for DNS configuration"
  value       = azurerm_public_ip.master_lb_public_ip.ip_address
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