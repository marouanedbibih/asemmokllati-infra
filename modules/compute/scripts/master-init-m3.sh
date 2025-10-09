#!/bin/bash
set -e

# Get values from Terraform template
FIRST_MASTER_IP="${FIRST_MASTER_IP}"
K3S_TOKEN="${k3s_token}"

curl -sfL https://get.k3s.io | K3S_TOKEN="$${K3S_TOKEN}" INSTALL_K3S_EXEC="server --server https://$${FIRST_MASTER_IP}:6443 --token $${K3S_TOKEN} --tls-san ${LOAD_BALANCER_IP}" sh -

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

sudo apt-get update
sudo apt-get install -y apache2-utils

# Setup kubectl without sudo
sudo mkdir -p /home/${admin_username}/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/${admin_username}/.kube/config
sudo chown ${admin_username}:${admin_username} /home/${admin_username}/.kube/config
echo 'export KUBECONFIG=/home/${admin_username}/.kube/config' >> /home/${admin_username}/.bashrc

# Wait for K3s to be ready
export KUBECONFIG=/home/${admin_username}/.kube/config
until kubectl get nodes; do sleep 5; done

sleep 30

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Configure MetalLB IP Address Pool using the Load Balancer IP
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool
  namespace: metallb-system
spec:
  addresses:
  - ${LOAD_BALANCER_IP}/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - metallb-pool
EOF

# Install Cert-Manager
kubectl create namespace cert-manager || true
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.14.4 \
  --set installCRDs=true \
  --set tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set tolerations[0].operator="Exists" \
  --set tolerations[0].effect="NoSchedule" \
  --wait

# Configure built-in Traefik to use LoadBalancer (MetalLB will assign the external IP)
kubectl patch service traefik -n kube-system -p '{"spec":{"type":"LoadBalancer","loadBalancerIP":"${LOAD_BALANCER_IP}","ports":[{"name":"web","port":80,"targetPort":8000,"protocol":"TCP"},{"name":"websecure","port":443,"targetPort":8443,"protocol":"TCP"}]}}'


# Install ArgoCD (check if not already installed)
kubectl create namespace argocd || true
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update


# Install ArgoCD with custom admin password hash and tolerations
helm install argocd argo/argo-cd -n argocd \
  --set server.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set server.tolerations[0].operator="Exists" \
  --set server.tolerations[0].effect="NoSchedule" \
  --set repoServer.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set repoServer.tolerations[0].operator="Exists" \
  --set repoServer.tolerations[0].effect="NoSchedule" \
  --set controller.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set controller.tolerations[0].operator="Exists" \
  --set controller.tolerations[0].effect="NoSchedule" \
  --set server.extraArgs[0]="--insecure" \
  --wait

sleep 30

# Generate the password hash
ARGOCD_ADMIN_PASSWORD_HASH=$(htpasswd -nbBC 10 "" "${ARGOCD_PASSWORD}" | tr -d ':\n' | sed 's/$2y/$2a/')

# Upgrade ArgoCD with new password
helm upgrade argocd argo/argo-cd -n argocd \
  --set configs.secret.argocdServerAdminPassword="$ARGOCD_ADMIN_PASSWORD_HASH" \
  --reuse-values

# Expose ArgoCD via Traefik Ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  rules:
  - host: argocd.${DOMAIN_NAME}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
  tls:
  - hosts:
    - argocd.${DOMAIN_NAME}
EOF

echo "Third master joined the cluster and installed ArgoCD, Cert-Manager, and Ingress."

# Configure GitHub repository credentials for ArgoCD
GITHUB_TOKEN="${GITHUB_TOKEN}"
GITHUB_REPO="${GITHUB_REPO}"
GITHUB_BRANCH="${GITHUB_BRANCH}"

# Wait for ArgoCD server to be ready before applying bootstrap
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Apply the bootstrap configuration from GitHub repository
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPO" ] && [ -n "$GITHUB_BRANCH" ]; then
    echo "Applying ArgoCD bootstrap configuration from GitHub repository: $GITHUB_REPO on branch: $GITHUB_BRANCH"
    
    # Download the bootstrap.yaml with authentication if token is provided
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -H "Authorization: token $GITHUB_TOKEN" \
             -H "Accept: application/vnd.github.v3.raw" \
             -o /tmp/bootstrap.yaml \
             "https://api.github.com/repos/$GITHUB_REPO/contents/bootstrap.yaml?ref=$GITHUB_BRANCH"
    else
        curl -o /tmp/bootstrap.yaml \
             "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/bootstrap.yaml"
    fi
    
    # Apply the bootstrap configuration
    kubectl apply -f /tmp/bootstrap.yaml
    
    # Clean up
    rm -f /tmp/bootstrap.yaml
    
    echo "ArgoCD bootstrap configuration applied successfully"
else
    echo "Warning: GitHub configuration incomplete. Skipping bootstrap application."
    echo "GITHUB_TOKEN: $([ -n "$GITHUB_TOKEN" ] && echo "provided" || echo "missing")"
    echo "GITHUB_REPO: $GITHUB_REPO"
    echo "GITHUB_BRANCH: $GITHUB_BRANCH"
fi

