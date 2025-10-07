# Monitoring Namespace
# Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  depends_on = [kubectl_manifest.letsencrypt_prod, null_resource.wait_for_longhorn]
  
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/name"     = "monitoring"
      "app.kubernetes.io/instance" = "monitoring"
    }
  }
}


# Prometheus Helm Release
resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace.monitoring, null_resource.wait_for_longhorn]
  
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.5.0"

  # Minimal resource configuration for K3s
  values = [
    <<-YAML
      # Disable components we don't need to save resources
      alertmanager:
        enabled: true
        alertmanagerSpec:
          resources:
            requests:
              cpu: 125m
              memory: 256Mi
            limits:
              cpu: 250m
              memory: 512Mi
          nodeSelector:
            node-role.kubernetes.io/control-plane: "true"
          tolerations:
          - key: "node-role.kubernetes.io/control-plane"
            operator: "Exists"
            effect: "NoSchedule"

      grafana:
        enabled: true
        adminUser: "${var.grafana_admin_username}"
        adminPassword: "${var.grafana_admin_password}"
        resources:
          requests:
            cpu: 250m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 512Mi
        nodeSelector:
          node-role.kubernetes.io/control-plane: "true"
        tolerations:
        - key: "node-role.kubernetes.io/control-plane"
          operator: "Exists"
          effect: "NoSchedule"
        ingress:
          enabled: true
          ingressClassName: "traefik"
          annotations:
            cert-manager.io/cluster-issuer: "letsencrypt-prod"
            traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
          hosts:
            - grafana.${var.domain_name}
          tls:
            - secretName: grafana-tls
              hosts:
                - grafana.${var.domain_name}

      prometheus:
        enabled: true
        prometheusSpec:
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 750m
              memory: 1536Mi
          nodeSelector:
            node-role.kubernetes.io/control-plane: "true"
          tolerations:
          - key: "node-role.kubernetes.io/control-plane"
            operator: "Exists"
            effect: "NoSchedule"
          retention: "7d"  # Keep data for 7 days
          retentionSize: "2GB"  # Limit storage to 2GB

      # Disable components to save resources
      kubeStateMetrics:
        enabled: true
        resources:
          requests:
            cpu: 10m
            memory: 32Mi
          limits:
            cpu: 50m
            memory: 64Mi

      nodeExporter:
        enabled: true
        resources:
          requests:
            cpu: 10m
            memory: 32Mi
          limits:
            cpu: 50m
            memory: 64Mi

      # Disable unnecessary components
      kubeEtcd:
        enabled: false
      kubeControllerManager:
        enabled: false
      kubeScheduler:
        enabled: false
      kubeProxy:
        enabled: false
      kubelet:
        enabled: false

      # Prometheus Operator
      prometheusOperator:
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
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
  timeout       = 600
}

# Wait for Prometheus to be ready
resource "null_resource" "wait_for_prometheus" {
  depends_on = [helm_release.prometheus, null_resource.wait_for_longhorn]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "⏳ Waiting for Prometheus to be ready..."
      
      # Wait for Prometheus pods to be ready
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s || true
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s || true
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager -n monitoring --timeout=300s || true
      
      echo "✅ Prometheus monitoring stack is ready!"
    EOT
  }
}

# Grafana Certificate
resource "kubectl_manifest" "grafana_certificate" {
  depends_on = [null_resource.wait_for_prometheus, null_resource.wait_for_longhorn]
  
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: grafana-cert
      namespace: monitoring
    spec:
      secretName: grafana-tls
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      dnsNames:
      - grafana.${var.domain_name}
  YAML
}

# Test monitoring setup
resource "null_resource" "test_monitoring" {
  depends_on = [kubectl_manifest.grafana_certificate, null_resource.wait_for_longhorn]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "🧪 Testing monitoring stack deployment..."
      
      # Wait for all monitoring components
      kubectl wait --for=condition=available --timeout=300s deployment/prometheus-kube-prometheus-operator -n monitoring || true
      kubectl wait --for=condition=available --timeout=300s deployment/prometheus-grafana -n monitoring || true
      kubectl wait --for=condition=available --timeout=300s statefulset/alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring || true
      
      # Check monitoring pods
      echo "📋 Monitoring pods:"
      kubectl get pods -n monitoring
      
      # Check monitoring services
      echo "📋 Monitoring services:"
      kubectl get svc -n monitoring
      
      # Check Grafana ingress
      echo "📋 Grafana ingress:"
      kubectl get ingress -n monitoring
      
      # Check Grafana certificate
      echo "📋 Grafana certificate:"
      kubectl get certificate -n monitoring
      
      # Get Grafana admin password
      GRAFANA_PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d 2>/dev/null || echo "${var.grafana_admin_password}")
      echo "🔑 Grafana admin password: $GRAFANA_PASSWORD"
      
      # Get Traefik Ingress Controller external IP
      INGRESS_IP=$(kubectl get service traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      if [ ! -z "$INGRESS_IP" ] && [ "$INGRESS_IP" != "null" ]; then
        echo "✅ Grafana will be available at: https://grafana.marouanedbibih.studio"
        echo "🌐 Make sure your DNS A record points to: $INGRESS_IP"
        echo "🔑 Grafana login: admin / $GRAFANA_PASSWORD"
        echo "📊 Prometheus will be available at: http://$INGRESS_IP:9090 (via port-forward)"
        echo "�� AlertManager will be available at: http://$INGRESS_IP:9093 (via port-forward)"
      fi
      
      echo "✅ Monitoring stack test completed!"
    EOT
  }
}