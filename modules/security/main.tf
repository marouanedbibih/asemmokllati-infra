# Network Security Group for K3S Cluster
resource "azurerm_network_security_group" "k3s_nsg" {
  name                = "k3s-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow SSH access
  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Kubernetes API Server (6443)
  security_rule {
    name                       = "AllowKubernetesAPI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow K3S Supervisor Port (6444) - for HA setup
  security_rule {
    name                       = "AllowK3SSupervisor"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6444"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow etcd client communication (2379-2380)
  security_rule {
    name                       = "AllowEtcdClient"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow Flannel VXLAN (8472/UDP)
  security_rule {
    name                       = "AllowFlannelVXLAN"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "8472"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow Kubelet API (10250)
  security_rule {
    name                       = "AllowKubeletAPI"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow NodePort Services (30000-32767)
  security_rule {
    name                       = "AllowNodePorts"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP traffic (80)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS traffic (443)
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Outbound rules
  # Allow HTTP outbound for package updates and K3s installation
  security_rule {
    name                       = "AllowHTTPOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow HTTPS outbound for secure downloads
  security_rule {
    name                       = "AllowHTTPSOutbound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow DNS outbound
  security_rule {
    name                       = "AllowDNSOutbound"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow all outbound traffic to internet (fallback)
  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow all outbound traffic within VNet
  security_rule {
    name                       = "AllowOutboundVNet"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "10.0.0.0/16"
  }
}

# Associate K3S NSG with K3S Cluster Subnet
resource "azurerm_subnet_network_security_group_association" "k3s_cluster_subnet_nsg" {
  subnet_id                 = var.k3s_cluster_subnet_id
  network_security_group_id = azurerm_network_security_group.k3s_nsg.id
}