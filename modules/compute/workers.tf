# VM Scale Set for Dev Environment
resource "azurerm_linux_virtual_machine_scale_set" "dev_vmss" {
  depends_on = [azurerm_linux_virtual_machine.k3s_master_1]
  name                = "k3s-dev-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.dev_vm_size != null ? var.dev_vm_size : "Standard_B1s"
  instances           = var.dev_min_instances
  admin_username      = var.admin_username

  disable_password_authentication = false
  admin_password                  = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface {
    name    = "dev-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.k3s_cluster_subnet_id
    }
  }

  # K3S worker node installation script
  custom_data = base64encode(templatefile("${path.module}/scripts/init-worker.sh", {
    k3s_token      = var.k3s_token
    master_ip      = azurerm_network_interface.master_1_nic.private_ip_address
    environment    = "dev"
    admin_username = var.admin_username
  }))

  tags = merge(var.tags, {
    "Role"          = "worker",
    "Environment"   = "dev",
    "K3S-Node-Type" = "agent"
  })
}

# VM Scale Set for Prod Environment
resource "azurerm_linux_virtual_machine_scale_set" "prod_vmss" {
  depends_on = [azurerm_linux_virtual_machine.k3s_master_1]
  name                = "k3s-prod-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.prod_vm_size != null ? var.prod_vm_size : "Standard_B1ms"
  instances           = var.prod_min_instances
  admin_username      = var.admin_username

  disable_password_authentication = false
  admin_password                  = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface {
    name    = "prod-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.k3s_cluster_subnet_id
    }
  }

  # K3S worker node installation script
  custom_data = base64encode(templatefile("${path.module}/scripts/init-worker.sh", {
    k3s_token      = var.k3s_token
    master_ip      = azurerm_network_interface.master_1_nic.private_ip_address
    environment    = "prod"
    admin_username = var.admin_username
  }))

  tags = merge(var.tags, {
    "Role"          = "worker",
    "Environment"   = "prod",
    "K3S-Node-Type" = "agent"
  })
}

# Auto-scaling for Dev Environment
resource "azurerm_monitor_autoscale_setting" "dev_autoscale" {
  name                = "k3s-dev-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.dev_vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.dev_min_instances
      minimum = var.dev_min_instances
      maximum = var.dev_max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.dev_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.dev_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  depends_on = [azurerm_linux_virtual_machine_scale_set.dev_vmss]

  tags = var.tags
}

# Auto-scaling for Prod Environment
resource "azurerm_monitor_autoscale_setting" "prod_autoscale" {
  name                = "k3s-prod-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.prod_vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.prod_min_instances
      minimum = var.prod_min_instances
      maximum = var.prod_max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.prod_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.prod_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT15M"
      }
    }
  }

  depends_on = [azurerm_linux_virtual_machine_scale_set.prod_vmss]

  tags = var.tags
}