# Outputs for kubernetes-credentials module

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = var.kubeconfig_output_path
  depends_on  = [null_resource.fetch_kubeconfig]
}

output "master_ip" {
  description = "IP address of the K3s master node"
  value       = var.master_public_ip
}

output "kubeconfig_content" {
  description = "Content of the kubeconfig file as string"
  value       = base64decode(data.external.kubeconfig_content.result.content)
  depends_on  = [null_resource.fetch_kubeconfig]
  sensitive   = true
}

output "kubeconfig_instructions" {
  description = "Instructions for using the kubeconfig"
  value = <<-EOT
    To use the kubeconfig:
    
    1. Load environment variable:
       export KUBECONFIG=${var.kubeconfig_output_path}
    
    2. Or use the helper script:
       source ./load-kubeconfig.sh
    
    3. Test connection:
       kubectl get nodes
       kubectl cluster-info
  EOT
}