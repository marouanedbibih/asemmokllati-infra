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

output "master_1_nic_id" {
  description = "ID of master 1 network interface"
  value       = azurerm_network_interface.master_1_nic.id
}

output "master_2_nic_id" {
  description = "ID of master 2 network interface"
  value       = azurerm_network_interface.master_2_nic.id
}

output "master_3_nic_id" {
  description = "ID of master 3 network interface"
  value       = azurerm_network_interface.master_3_nic.id
}