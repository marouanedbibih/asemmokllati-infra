#!/bin/bash
set -e

# Debug: Log script execution
echo "$(date): Starting K3S master installation..." | sudo tee -a /var/log/k3s-install.log
exec > >(sudo tee -a /var/log/k3s-install.log) 2>&1

echo "Starting K3S master installation..."

# Update system
apt-get update -y
apt-get install -y curl

# Install K3S server with public IP in TLS certificate
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --node-name master-init --token ${k3s_token} --tls-san ${master_public_ip} --cluster-init" sh -

# Wait for K3S to start
echo "Waiting for K3S to start..."
sleep 30

# Verify K3S is running
systemctl status k3s --no-pager || true

# Wait for node to be ready
echo "Waiting for node to be ready..."
timeout 300 bash -c 'until kubectl get nodes | grep -q "Ready"; do sleep 10; done' || true

# Copy kubeconfig for admin user
echo "Setting up kubeconfig for ${admin_username}..."
mkdir -p /home/${admin_username}/.kube
cp /etc/rancher/k3s/k3s.yaml /home/${admin_username}/.kube/config

# Update server address in kubeconfig to use public IP
sed -i "s/127.0.0.1/${master_public_ip}/g" /home/${admin_username}/.kube/config

# Set proper ownership
chown -R ${admin_username}:${admin_username} /home/${admin_username}/.kube
chmod 600 /home/${admin_username}/.kube/config

# Display cluster info
echo "K3S master installation completed!"
echo "Cluster token: ${k3s_token}"
echo "Master public IP: ${master_public_ip}"
echo "Kubeconfig available at: /home/${admin_username}/.kube/config"

# Test cluster connectivity
kubectl get nodes || echo "Warning: kubectl test failed"

echo "Installation finished successfully!"