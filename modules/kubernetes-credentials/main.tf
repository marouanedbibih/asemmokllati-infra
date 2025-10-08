# Kubernetes Credentials Module
# This module handles fetching kubeconfig after infrastructure is deployed

# Wait for K3s to be fully ready before fetching kubeconfig
resource "null_resource" "wait_for_k3s" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      echo "🚀 Waiting for K3s master to be ready..."
      
      # Test SSH connectivity first
      echo "🔗 Testing SSH connectivity..."
      for i in {1..12}; do
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           -o ConnectTimeout=10 -o BatchMode=yes \
           -p ${var.ssh_port} \
           -i ${var.ssh_private_key_path} \
           ${var.admin_username}@${var.master_public_ip} \
           'echo "SSH connection successful"' 2>/dev/null; then
          echo "✅ SSH connection established"
          break
        else
          echo "⏳ Waiting for SSH... (attempt $i/12)"
          sleep 30
        fi
        
        if [ $i -eq 12 ]; then
          echo "❌ Failed to establish SSH connection after 6 minutes"
          exit 1
        fi
      done
      
      # Wait for K3s service to be ready
      echo "⏳ Waiting for K3s service to be ready..."
      for i in {1..20}; do
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           -p ${var.ssh_port} \
           -i ${var.ssh_private_key_path} \
           ${var.admin_username}@${var.master_public_ip} \
           'sudo systemctl is-active k3s' 2>/dev/null | grep -q "active"; then
          echo "✅ K3s service is active"
          break
        else
          echo "⏳ Waiting for K3s service... (attempt $i/20)"
          sleep 15
        fi
        
        if [ $i -eq 20 ]; then
          echo "❌ K3s service not ready after 5 minutes"
          exit 1
        fi
      done
      
      # Wait for K3s API server to be responsive
      echo "⏳ Waiting for K3s API server..."
      for i in {1..20}; do
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           -p ${var.ssh_port} \
           -i ${var.ssh_private_key_path} \
           ${var.admin_username}@${var.master_public_ip} \
           'sudo k3s kubectl get nodes' 2>/dev/null; then
          echo "✅ K3s API server is responsive"
          break
        else
          echo "⏳ Waiting for K3s API server... (attempt $i/20)"
          sleep 15
        fi
        
        if [ $i -eq 20 ]; then
          echo "❌ K3s API server not responsive after 5 minutes"
          exit 1
        fi
      done
      
      echo "🎉 K3s master is fully ready!"
    EOT
  }

  triggers = {
    master_ip = var.master_public_ip
  }
}

# Fetch kubeconfig from K3s master
resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.wait_for_k3s]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      echo "📋 Fetching K3s kubeconfig..."
      
      # Create backup of existing kubeconfig if it exists
      if [ -f "${var.kubeconfig_output_path}" ]; then
        echo "💾 Backing up existing kubeconfig..."
        cp "${var.kubeconfig_output_path}" "${var.kubeconfig_output_path}.backup.$(date +%s)"
      fi
      
      # Fetch kubeconfig with proper server IP
      echo "⬇️  Downloading kubeconfig from master..."
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=30 \
        -p ${var.ssh_port} \
        -i ${var.ssh_private_key_path} \
        ${var.admin_username}@${var.master_public_ip} \
        'sudo cat /etc/rancher/k3s/k3s.yaml' | \
      sed "s/127.0.0.1/${var.master_public_ip}/g" > "${var.kubeconfig_output_path}"
      
      # Set proper permissions
      chmod 600 "${var.kubeconfig_output_path}"
      
      echo "✅ Kubeconfig saved to: ${var.kubeconfig_output_path}"
      
      # Verify kubeconfig works
      echo "🧪 Testing kubeconfig..."
      export KUBECONFIG="${var.kubeconfig_output_path}"
      
      if kubectl cluster-info --request-timeout=30s >/dev/null 2>&1; then
        echo "✅ Kubeconfig is working correctly"
        
        # Display cluster information
        echo ""
        echo "📋 Cluster Information:"
        kubectl cluster-info
        echo ""
        echo "🖥️  Nodes:"
        kubectl get nodes -o wide
        echo ""
        echo "🔧 Namespaces:"
        kubectl get namespaces
        
      else
        echo "❌ Kubeconfig test failed"
        echo "🔍 Troubleshooting information:"
        echo "   Master IP: ${var.master_public_ip}"
        echo "   Kubeconfig path: ${var.kubeconfig_output_path}"
        exit 1
      fi
    EOT
  }

  # Clean up kubeconfig on destroy
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      echo "🧹 Cleaning up kubeconfig file..."
      KUBECONFIG_PATH="${self.triggers.kubeconfig_path}"
      if [ -f "$KUBECONFIG_PATH" ]; then
        rm -f "$KUBECONFIG_PATH"
        echo "✅ Kubeconfig file removed: $KUBECONFIG_PATH"
      else
        echo "ℹ️  Kubeconfig file not found, nothing to clean up"
      fi
    EOT
  }

  triggers = {
    master_ip = var.master_public_ip
    kubeconfig_path = var.kubeconfig_output_path
  }
}

# Set kubeconfig environment variable
resource "null_resource" "set_kubeconfig_env" {
  depends_on = [null_resource.fetch_kubeconfig]

  provisioner "local-exec" {
    command = <<-EOT
      echo "🔧 Setting up kubeconfig environment..."
      
      # Create a script to easily load kubeconfig
      cat > load-kubeconfig.sh << 'EOF'
#!/bin/bash
# Load kubeconfig for K3s cluster

KUBECONFIG_PATH="${var.kubeconfig_output_path}"

if [ -f "$KUBECONFIG_PATH" ]; then
    export KUBECONFIG="$KUBECONFIG_PATH"
    echo "✅ KUBECONFIG set to: $KUBECONFIG_PATH"
    
    # Test connection
    if kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then
        echo "🎉 Successfully connected to K3s cluster!"
        kubectl get nodes
    else
        echo "❌ Failed to connect to cluster"
        exit 1
    fi
else
    echo "❌ Kubeconfig file not found at: $KUBECONFIG_PATH"
    exit 1
fi
EOF
      
      chmod +x load-kubeconfig.sh
      echo "✅ Created load-kubeconfig.sh script"
      
      # Create instructions
      echo ""
      echo "🚀 Next steps:"
      echo "1. Load kubeconfig: source ./load-kubeconfig.sh"
      echo "2. Or manually: export KUBECONFIG=${var.kubeconfig_output_path}"
      echo "3. Test connection: kubectl get nodes"
    EOT
  }

  triggers = {
    kubeconfig_path = var.kubeconfig_output_path
  }
}

# Read kubeconfig file content after it's created
data "external" "kubeconfig_content" {
  program = ["bash", "-c", "echo '{\"content\": \"'$(cat ${var.kubeconfig_output_path} | base64 -w 0)'\"}'"]
  
  depends_on = [null_resource.fetch_kubeconfig]
}