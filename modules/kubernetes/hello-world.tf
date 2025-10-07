# =============================================================================
# HELLO WORLD APPLICATION CONFIGURATION
# =============================================================================
# Simple hello-world application with Traefik Ingress and TLS
# Deployed after Let's Encrypt cluster issuer is ready
# =============================================================================

# Hello World Deployment
resource "kubectl_manifest" "hello_world_deployment" {
  depends_on = [kubectl_manifest.letsencrypt_prod]
  
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: hello-world
      name: hello-world
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: hello-world
      strategy:
        rollingUpdate:
          maxSurge: 1
          maxUnavailable: 0
        type: RollingUpdate
      template:
        metadata:
          labels:
            app: hello-world
        spec:
          containers:
          - image: rancher/hello-world
            imagePullPolicy: Always
            name: hello-world
            ports:
            - containerPort: 80
              protocol: TCP
            resources:
              requests:
                cpu: 10m
                memory: 16Mi
              limits:
                cpu: 50m
                memory: 64Mi
          restartPolicy: Always
          # Force deployment on control-plane node for resource efficiency
          nodeSelector:
            node-role.kubernetes.io/control-plane: "true"
          tolerations:
          - key: "node-role.kubernetes.io/control-plane"
            operator: "Exists"
            effect: "NoSchedule"
          - key: "node-role.kubernetes.io/master"
            operator: "Exists"
            effect: "NoSchedule"
          - key: "CriticalAddonsOnly"
            operator: "Exists"
  YAML
}

# Hello World Service
resource "kubectl_manifest" "hello_world_service" {
  depends_on = [kubectl_manifest.hello_world_deployment]
  
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: hello-world
      namespace: default
      labels:
        app: hello-world
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 80
        name: http
      selector:
        app: hello-world
      type: ClusterIP
  YAML
}

# Hello World Certificate (Production)
resource "kubectl_manifest" "hello_world_certificate" {
  depends_on = [kubectl_manifest.hello_world_service]
  
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: hello-world-cert
      namespace: default
    spec:
      secretName: tls-hello-world-ingress
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      dnsNames:
      - hello.${var.domain_name}
  YAML
}

# Hello World Ingress for Traefik
resource "kubectl_manifest" "hello_world_ingress" {
  depends_on = [kubectl_manifest.hello_world_certificate]
  
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: hello-world
      namespace: default
      annotations:
        kubernetes.io/ingress.class: "traefik"
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
        traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
        traefik.ingress.kubernetes.io/router.tls: "true"
    spec:
      tls:
      - hosts:
        - hello.marouanedbibih.studio
        secretName: tls-hello-world-ingress
      rules:
      - host: hello.${var.domain_name}
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hello-world
                port:
                  number: 80
  YAML
}

# Wait for Hello World to be ready
resource "null_resource" "wait_for_hello_world" {
  depends_on = [kubectl_manifest.hello_world_ingress]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "⏳ Waiting for Hello World to be ready..."
      
      # Wait for Hello World deployment to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/hello-world -n default
      
      # Wait for Hello World pods to be ready
      kubectl wait --for=condition=ready pod -l app=hello-world -n default --timeout=300s
      
      echo "✅ Hello World is ready!"
    EOT
  }
}

# Test Hello World deployment
resource "null_resource" "test_hello_world" {
  depends_on = [null_resource.wait_for_hello_world]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "🧪 Testing Hello World deployment..."
      
      # Check Hello World pods
      echo "📋 Hello World pods:"
      kubectl get pods -l app=hello-world -n default -o wide
      
      # Check Hello World service
      echo "📋 Hello World service:"
      kubectl get svc hello-world -n default
      
      # Check Hello World ingress
      echo "📋 Hello World ingress:"
      kubectl get ingress hello-world -n default
      
      # Check Hello World certificate
      echo "📋 Hello World certificate:"
      kubectl get certificate hello-world-cert -n default
      
      # Get Traefik LoadBalancer external IP
      TRAEFIK_IP=$(kubectl get service traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      if [ ! -z "$TRAEFIK_IP" ] && [ "$TRAEFIK_IP" != "null" ]; then
        echo "✅ Hello World will be available at: https://hello.marouanedbibih.studio"
        echo "🌐 Make sure your DNS A record points to: $TRAEFIK_IP"
        echo "🧪 Test connectivity:"
        echo "   curl -I https://hello.marouanedbibih.studio"
        echo "   curl https://hello.marouanedbibih.studio"
      fi
      
      echo "✅ Hello World deployment test completed!"
    EOT
  }
}