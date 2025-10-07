terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Wait for cluster to be ready
resource "time_sleep" "wait_for_cluster" {
  count = var.k3s_cluster_ready ? 1 : 0
  create_duration = "30s"
}

# Wait for Traefik to be ready (K3s default ingress)
resource "null_resource" "wait_for_traefik" {
  depends_on = [time_sleep.wait_for_cluster]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "⏳ Waiting for Traefik to be ready..."
      
      # Wait for Traefik pods to be ready
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=300s
      
      # Wait for Traefik service to get external IP
      echo "⏳ Waiting for Traefik LoadBalancer service..."
      for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ ! -z "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
          echo "✅ Traefik LoadBalancer IP: $EXTERNAL_IP"
          break
        fi
        echo "⏳ Waiting for LoadBalancer IP... ($i/30)"
        sleep 10
      done
      
      echo "✅ Traefik is ready!"
    EOT
  }
}

# Cert-Manager Namespace
resource "kubernetes_namespace" "cert_manager" {
  depends_on = [null_resource.wait_for_traefik]
  
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

# Cert-Manager Helm Release
resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]
  
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.13.2"

  # Configure cert-manager
  values = [
    <<-YAML
      installCRDs: true
      global:
        leaderElection:
          namespace: cert-manager
      resources:
        requests:
          cpu: 10m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 128Mi
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
    YAML
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 300
}

# Wait for cert-manager to be ready
resource "null_resource" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "⏳ Waiting for cert-manager to be ready..."
      
      # Wait for cert-manager pods to be ready
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=webhook -n cert-manager --timeout=300s
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cainjector -n cert-manager --timeout=300s
      
      echo "✅ cert-manager is ready!"
    EOT
  }
}


# Let's Encrypt ClusterIssuer (Production) - Using Traefik
resource "kubectl_manifest" "letsencrypt_prod" {
  depends_on = [null_resource.wait_for_cert_manager]
  
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.letsencrypt_email}
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
              class: traefik
  YAML
}
