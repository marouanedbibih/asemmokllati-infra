#!/bin/bash
set -e

# Get values from Terraform template
FIRST_MASTER_IP="${FIRST_MASTER_IP}"
K3S_TOKEN="${k3s_token}"

curl -sfL https://get.k3s.io | K3S_TOKEN="$${K3S_TOKEN}" INSTALL_K3S_EXEC="server --server https://$${FIRST_MASTER_IP}:6443 --token $${K3S_TOKEN} --tls-san ${LOAD_BALANCER_IP}" sh -

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Setup kubectl without sudo
sudo mkdir -p /home/${admin_username}/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/${admin_username}/.kube/config
sudo chown ${admin_username}:${admin_username} /home/${admin_username}/.kube/config
echo 'export KUBECONFIG=/home/${admin_username}/.kube/config' >> /home/${admin_username}/.bashrc

# Wait for K3s to be ready
export KUBECONFIG=/home/${admin_username}/.kube/config
until kubectl get nodes; do sleep 5; done

echo "Second master joined the cluster."