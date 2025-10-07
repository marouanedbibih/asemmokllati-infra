# Longhorn Namespace
resource "kubernetes_namespace" "longhorn_system" {
  depends_on = [null_resource.wait_for_rancher]
  
  metadata {
    name = "longhorn-system"
    labels = {
      "app.kubernetes.io/name" = "longhorn"
      "app.kubernetes.io/instance" = "longhorn"
    }
  }
}

# Longhorn Helm Release
resource "helm_release" "longhorn" {
  depends_on = [
    null_resource.wait_for_rancher
  ]
  
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = kubernetes_namespace.longhorn_system.metadata[0].name
  version    = "1.5.3"  # Latest stable version

  # Minimal resource configuration for 3 CPU, 6GB RAM cluster
  values = [
    <<-YAML
      # Global settings - minimal configuration
      global:
        cattle:
          systemDefaultRegistry: ""
      
      # Longhorn Manager - minimal resources
      longhornManager:
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
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      
      # Longhorn Driver - minimal resources
      longhornDriver:
        resources:
          requests:
            cpu: 125m
            memory: 256Mi
          limits:
            cpu: 250m
            memory: 512Mi
        tolerations:
        - key: "node-role.kubernetes.io/control-plane"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      
      # Longhorn UI - minimal resources
      longhornUI:
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
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      
      # Minimal default settings for small cluster
      defaultSettings:
        defaultDataPath: "/var/lib/longhorn/"
        defaultDataLocality: "disabled"
        replicaSoftAntiAffinity: "false"
        storageOverProvisioningPercentage: "200"
        storageMinimalAvailablePercentage: "10"
        upgradeChecker: "false"
        defaultReplicaCount: "1"  # Reduced from 3 to 1 for minimal setup
        defaultLonghornStaticStorageClass: "longhorn"
        backupstorePollInterval: "600"  # Increased to reduce load
        taintToleration: "node-role.kubernetes.io/control-plane:NoSchedule;node-role.kubernetes.io/master:NoSchedule;CriticalAddonsOnly:Exists"
        systemManagedComponentsNodeSelector: "node-role.kubernetes.io/control-plane=true"
        priorityClass: ""
        autoSalvage: "true"
        autoDeletePodWhenVolumeDetachedUnexpectedly: "true"
        disableSchedulingOnCordonedNode: "true"
        replicaZoneSoftAntiAffinity: "false"  # Disabled for single replica
        volumeAttachmentRecoveryPolicy: "wait"
        nodeDownPodDeletionPolicy: "delete-both-statefulset-and-deployment-pod"
        mkfsExt4Parameters: ""
        guaranteedEngineManagerCPU: "5"  # Reduced from 12 to 5
        guaranteedReplicaManagerCPU: "5"  # Reduced from 12 to 5
        concurrentReplicaRebuildPerNodeLimit: "1"  # Limit rebuilds
        concurrentVolumeBackupRestorePerNodeLimit: "1"  # Limit restores
      
      # Persistence settings - single replica for minimal setup
      persistence:
        defaultClass: true
        defaultClassReplicaCount: 1  # Reduced from 3 to 1
        reclaimPolicy: Retain
      
      # Longhorn Engine - minimal resources
      longhornEngine:
        resources:
          requests:
            cpu: 125m
            memory: 256Mi
          limits:
            cpu: 250m
            memory: 512Mi
        tolerations:
        - key: "node-role.kubernetes.io/control-plane"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      
      # CSI settings - minimal replicas
      csi:
        kubeletRootDir: "/var/lib/kubelet"
        attacherReplicaCount: 1
        provisionerReplicaCount: 1
        resizerReplicaCount: 1
        snapshotterReplicaCount: 1
        nodeDriverRegistrarReplicaCount: 1
    YAML
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 600  # 10 minutes for Longhorn to start
}

# Wait for Longhorn to be ready
resource "null_resource" "wait_for_longhorn" {
  depends_on = [helm_release.longhorn]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "⏳ Waiting for Longhorn to be ready..."
      
      # Wait for Longhorn pods to be ready
      kubectl wait --for=condition=ready pod -l app=longhorn-manager -n longhorn-system --timeout=600s
      kubectl wait --for=condition=ready pod -l app=longhorn-ui -n longhorn-system --timeout=300s
      
      # Wait for Longhorn storage class to be available
      echo "⏳ Waiting for Longhorn storage class..."
      kubectl wait --for=condition=Ready storageclass/longhorn --timeout=300s
      
      echo "✅ Longhorn is ready!"
    EOT
  }
}

# Set Longhorn as default storage class
resource "null_resource" "set_default_storage_class" {
  depends_on = [null_resource.wait_for_longhorn]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "🔧 Setting Longhorn as default storage class..."
      
      # Remove default annotation from other storage classes
      kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class- --overwrite || true
      
      # Set Longhorn as default
      kubectl annotate storageclass longhorn storageclass.kubernetes.io/is-default-class=true --overwrite
      
      # Verify default storage class
      echo "📋 Default storage class:"
      kubectl get storageclass
      
      echo "✅ Longhorn set as default storage class!"
    EOT
  }
}

# Longhorn Certificate (Production)
resource "kubectl_manifest" "longhorn_certificate" {
  depends_on = [null_resource.set_default_storage_class]
  
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: longhorn-cert
      namespace: longhorn-system
    spec:
      secretName: tls-longhorn-ingress
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      dnsNames:
      - longhorn.marouanedbibih.studio
  YAML
}

# Longhorn Ingress for Traefik
resource "kubectl_manifest" "longhorn_ingress" {
  depends_on = [kubectl_manifest.longhorn_certificate]
  
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: longhorn
      namespace: longhorn-system
      annotations:
        kubernetes.io/ingress.class: "traefik"
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
        traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
        traefik.ingress.kubernetes.io/router.tls: "true"
    spec:
      tls:
      - hosts:
        - longhorn.marouanedbibih.studio
        secretName: tls-longhorn-ingress
      rules:
      - host: longhorn.marouanedbibih.studio
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: longhorn-frontend
                port:
                  number: 80
  YAML
}

# Test Longhorn deployment
resource "null_resource" "test_longhorn" {
  depends_on = [kubectl_manifest.longhorn_ingress]
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${var.kubeconfig_path}
      
      echo "🧪 Testing Longhorn deployment..."
      
      # Wait for Longhorn deployment
      kubectl wait --for=condition=available --timeout=600s deployment/longhorn-ui -n longhorn-system
      kubectl wait --for=condition=available --timeout=600s deployment/longhorn-driver-deployer -n longhorn-system
      
      # Check Longhorn pods
      echo "📋 Longhorn pods:"
      kubectl get pods -n longhorn-system -o wide
      
      # Check Longhorn services
      echo "📋 Longhorn services:"
      kubectl get svc -n longhorn-system
      
      # Check storage classes
      echo "📋 Storage classes:"
      kubectl get storageclass
      
      # Check Longhorn volumes
      echo "📋 Longhorn volumes:"
      kubectl get volumes -n longhorn-system || echo "No volumes yet"
      
      # Check Longhorn ingress
      echo "📋 Longhorn ingress:"
      kubectl get ingress -n longhorn-system
      
      # Check Longhorn certificate
      echo "📋 Longhorn certificate:"
      kubectl get certificate -n longhorn-system
      
      # Get Traefik LoadBalancer external IP
      TRAEFIK_IP=$(kubectl get service traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      if [ ! -z "$TRAEFIK_IP" ] && [ "$TRAEFIK_IP" != "null" ]; then
        echo "✅ Longhorn UI will be available at: https://longhorn.marouanedbibih.studio"
        echo "🌐 Make sure your DNS A record points to: $TRAEFIK_IP"
        echo "🧪 Test connectivity:"
        echo "   curl -I https://longhorn.marouanedbibih.studio"
      fi
      
      echo "✅ Longhorn deployment test completed!"
    EOT
  }
}