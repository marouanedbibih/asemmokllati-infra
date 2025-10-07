#!/bin/bash
set -e

# Get custom token from Terraform template
K3S_TOKEN="${k3s_token}"

# Install K3s (initialize cluster with embedded etcd and custom token)
curl -sfL https://get.k3s.io | K3S_TOKEN="$${K3S_TOKEN}" INSTALL_K3S_EXEC="server --cluster-init --token $${K3S_TOKEN}" sh -

# Save the cluster token for verification
echo "$${K3S_TOKEN}" > /tmp/k3s-token

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

# Configure built-in Traefik to use NodePort
kubectl patch service traefik -n kube-system -p '{"spec":{"type":"NodePort","ports":[{"name":"web","port":80,"targetPort":8000,"nodePort":30080,"protocol":"TCP"},{"name":"websecure","port":443,"targetPort":8443,"nodePort":30443,"protocol":"TCP"}]}}'

echo "K3s cluster initialized on first master with Traefik configured."