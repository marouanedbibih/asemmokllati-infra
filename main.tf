locals {
  location     = "West Europe"
  project_name = "asemmokllati-k3s"
  environment  = "development"
  tags = {
    environment = local.environment
    project     = local.project_name
  }
}

resource "azurerm_resource_group" "asemmokllati-k3s-rg" {
  name     = "asemmokllati-k3s-rg"
  location = local.location
  tags     = local.tags
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  numeric = true
  special = false
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.asemmokllati-k3s-rg.name
  location            = local.location
  tags                = local.tags
}

# Security Module
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.asemmokllati-k3s-rg.name
  location            = local.location
  k3s_cluster_subnet_id = module.networking.k3s_cluster_subnet_id
  tags = local.tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  resource_group_name   = azurerm_resource_group.asemmokllati-k3s-rg.name
  location              = local.location
  tags                  = local.tags

  # Networking
  k3s_cluster_subnet_id = module.networking.k3s_cluster_subnet_id

  # VM Credentials
  admin_username = var.admin_username
  admin_password = var.admin_password

  # Master VM Configuration
  master_vm_size = "Standard_B2ms"
  
  # VMSS Configuration (autoscale-compatible sizes)
  dev_vm_size       = "Standard_B2s" 
  prod_vm_size      = "Standard_B2s"
  dev_min_instances = 2
  dev_max_instances = 4
  prod_min_instances = 2
  prod_max_instances = 4
  
  # K3s Configuration
  k3s_token     = var.k3s_token

  # ArgoCD Configuration
  argocd_admin_username = var.argocd_admin_username
  argocd_admin_password = var.argocd_admin_password

  depends_on = [module.security, module.networking]
}

# Kubernetes Credentials Module - Deploy separately after infrastructure
module "kubernetes_credentials" {
  source = "./modules/kubernetes-credentials"

  master_public_ip       = module.compute.master_public_ip
  admin_username         = var.admin_username
  ssh_private_key_path   = "~/.ssh/id_rsa"
  kubeconfig_output_path = "${path.module}/kubeconfig"

  depends_on = [module.compute]
}


