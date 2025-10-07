#!/bin/bash
set -e

# Debug: Log script execution
echo "$(date): Starting K3S worker installation..." | sudo tee -a /var/log/k3s-worker-install.log
exec > >(sudo tee -a /var/log/k3s-worker-install.log) 2>&1

echo "Starting K3S worker installation for ${environment} environment..."

# Update system
apt-get update -y
apt-get install -y curl

# Wait for master to be ready
echo "Waiting for master node to be ready..."
sleep 30

# Get instance metadata for unique node naming
INSTANCE_ID=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2021-02-01&format=text" | cut -c1-8)
NODE_NAME="${environment}-worker-$INSTANCE_ID"

echo "Installing K3s agent with node name: $NODE_NAME"

# Install K3s agent to join the cluster
curl -sfL https://get.k3s.io | K3S_TOKEN="${k3s_token}" sh -s - agent \
  --server https://${master_ip}:6443 \
  --token "${k3s_token}" \
  --node-name "$NODE_NAME" \
  --node-label environment=${environment}

# Enable and start the K3s agent service
systemctl enable k3s-agent
systemctl start k3s-agent

# Wait for the service to be ready
echo "Waiting for K3s agent to be ready..."
sleep 30

# Check service status
systemctl status k3s-agent --no-pager || true

echo "K3s worker installation completed!"
echo "Node name: $NODE_NAME"
echo "Environment: ${environment}"
echo "Master server: https://${master_ip}:6443"
echo "Installation finished successfully!"

# --- BEGIN: Add shutdown script to drain and delete node on scale-down ---
cat <<'EOF' > /usr/local/bin/k3s-node-drain.sh
#!/bin/bash
NODE_NAME=$(hostname)
KUBECONFIG=/etc/rancher/k3s/k3s.yaml
/usr/local/bin/kubectl --kubeconfig=$KUBECONFIG drain $NODE_NAME --ignore-daemonsets --delete-local-data --force || true
/usr/local/bin/kubectl --kubeconfig=$KUBECONFIG delete node $NODE_NAME || true
EOF

chmod +x /usr/local/bin/k3s-node-drain.sh

cat <<EOF | tee /etc/systemd/system/k3s-node-drain.service
[Unit]
Description=Drain K3s node before shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/k3s-node-drain.sh

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOF

systemctl enable k3s-node-drain.service
# --- END: Add shutdown script ---
