# Rancher Namespace
resource "kubernetes_namespace" "cattle_system" {
  depends_on = [kubectl_manifest.letsencrypt_prod]
  
  metadata {
    name = "cattle-system"
    labels = {
      "app.kubernetes.io/name" = "rancher"
      "app.kubernetes.io/instance" = "rancher"
    }
  }
}

# Rancher Helm Release
resource "helm_release" "rancher" {
  depends_on = [kubernetes_namespace.cattle_system]
  
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  namespace  = kubernetes_namespace.cattle_system.metadata[0].name
  version    = "2.12.2"  # Updated to support Kubernetes 1.33

  # Minimal resource configuration for easy deployment
  values = [
    <<-YAML
      hostname: rancher.${var.domain_name}
      
      # Minimal resource configuration
      resources:
        requests:
          cpu: 250m
          memory: 512Mi
        limits:
          cpu: 500m
          memory: 1Gi
      
      # Force deployment on master node
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
      
      # Tolerations for master node
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
      - key: "CriticalAddonsOnly"
        operator: "Exists"
      
      # Ingress configuration for Traefik
      ingress:
        tls:
          source: letsEncrypt
        extraAnnotations:
          cert-manager.io/cluster-issuer: "letsencrypt-prod"
          traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
          traefik.ingress.kubernetes.io/router.tls: "true"
      
      # Bootstrap password
      bootstrapPassword: "${var.rancher_admin_password}"
      
      # Disable telemetry and features to reduce resource usage
      global:
        cattle:
          psp:
            enabled: false
          systemDefaultRegistry: ""
      
      # Minimal replicas
      replicas: 1
      
      # Use Let's Encrypt for SSL
      letsEncrypt:
        email: ${var.letsencrypt_email}
        environment: production
      
      # Health check configuration
      extraEnv:
      - name: CATTLE_PROMETHEUS_METRICS
        value: "false"
      - name: CATTLE_AGENT_IMAGE
        value: "rancher/rancher-agent:v2.12.2"
      
      # Startup probe configuration
      startupProbe:
        httpGet:
          path: /healthz
          port: 80
        initialDelaySeconds: 30
        periodSeconds: 10
        timeoutSeconds: 5
        failureThreshold: 30
      
      # Liveness probe configuration
      livenessProbe:
        httpGet:
          path: /healthz
          port: 80
        initialDelaySeconds: 60
        periodSeconds: 20
        timeoutSeconds: 5
        failureThreshold: 3
      
      # Readiness probe configuration
      readinessProbe:
        httpGet:
          path: /healthz
          port: 80
        initialDelaySeconds: 30
        periodSeconds: 10
        timeoutSeconds: 5
        failureThreshold: 3
    YAML
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 600  # 10 minutes for Rancher to start
}

# Wait for Rancher to be ready
resource "null_resource" "wait_for_rancher" {
  depends_on = [helm_release.rancher]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "⏳ Waiting for Rancher to be ready..."
      
      # Wait for Rancher pods to be ready
      kubectl wait --for=condition=ready pod -l app=rancher -n cattle-system --timeout=900s
      
      # Wait for Rancher service to be available
      echo "⏳ Waiting for Rancher service..."
      kubectl wait --for=condition=ready pod -l app=rancher -n cattle-system --timeout=300s
      
      echo "✅ Rancher is ready!"
    EOT
  }
}

# Rancher Certificate (Production)
resource "kubectl_manifest" "rancher_certificate" {
  depends_on = [null_resource.wait_for_rancher]
  
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: rancher-cert
      namespace: cattle-system
    spec:
      secretName: tls-rancher-ingress
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      dnsNames:
      - rancher.${var.domain_name}
  YAML
}

# Rancher Ingress for Traefik
resource "kubectl_manifest" "rancher_ingress" {
  depends_on = [kubectl_manifest.rancher_certificate]
  
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: rancher
      namespace: cattle-system
      annotations:
        kubernetes.io/ingress.class: "traefik"
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
        traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
        traefik.ingress.kubernetes.io/router.tls: "true"
    spec:
      tls:
      - hosts:
        - rancher.${var.domain_name}
        secretName: tls-rancher-ingress
      rules:
      - host: rancher.${var.domain_name}
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rancher
                port:
                  number: 80
  YAML
}
