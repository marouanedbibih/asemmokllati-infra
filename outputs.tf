
output "azure_subscription_id" {
  description = "Azure Subscription ID (Sensitive)"
  value       = var.azure_subscription_id
  sensitive   = true
}

output "azure_tenant_id" {
  description = "Azure Tenant ID (Sensitive)"
  value       = var.azure_tenant_id
  sensitive   = true
}

output "azure_client_id" {
  description = "Azure Client ID (Sensitive)"
  value       = var.azure_client_id
  sensitive   = true
}

output "azure_client_secret" {
  description = "Azure Client Secret (Sensitive)"
  value       = var.azure_client_secret
  sensitive   = true
}

output "grafana_admin_password" {
  description = "Grafana admin password (Sensitive)"
  value       = var.grafana_admin_password
  sensitive   = true
}

# Load Balancer and SSH Access Information
output "load_balancer_public_ip" {
  description = "Public IP address of the master load balancer"
  value       = module.networking.master_lb_public_ip
}

output "ssh_access_info" {
  description = "SSH access information for each master node via load balancer"
  value = {
    load_balancer_ip = module.networking.master_lb_public_ip
    master_1_ssh = {
      port = 2221
      command = "ssh ${var.admin_username}@${module.networking.master_lb_public_ip} -p 2221"
    }
    master_2_ssh = {
      port = 2222
      command = "ssh ${var.admin_username}@${module.networking.master_lb_public_ip} -p 2222"
    }
    master_3_ssh = {
      port = 2223
      command = "ssh ${var.admin_username}@${module.networking.master_lb_public_ip} -p 2223"
    }
  }
}

output "ssh_commands" {
  description = "Ready-to-use SSH commands for each master node"
  value = [
    "ssh ${var.admin_username}@${module.networking.master_lb_public_ip} -p 2221  # Master 1",
    "ssh ${var.admin_username}@${module.networking.master_lb_public_ip} -p 2222  # Master 2",
    "ssh ${var.admin_username}@${module.networking.master_lb_public_ip} -p 2223  # Master 3"
  ]
}

# Networking outputs
output "vnet_info" {
  description = "Virtual network information"
  value = {
    vnet_id = module.networking.vnet_id
    vnet_name = module.networking.vnet_name
    address_space = module.networking.vnet_address_space
  }
}

output "k3s_cluster_info" {
  description = "K3S cluster networking information"
  value = {
    subnet_id = module.networking.k3s_cluster_subnet_id
    subnet_address_prefix = module.networking.k3s_cluster_subnet_address_prefix
    load_balancer_ip = module.networking.master_lb_public_ip
    http_endpoint = "http://${module.networking.master_lb_public_ip}"
    https_endpoint = "https://${module.networking.master_lb_public_ip}"
  }
}
