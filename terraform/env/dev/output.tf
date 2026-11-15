#-----------------------------------------------------------------------------
# DEV Environment - Outputs
# View after apply with: terraform output
#-----------------------------------------------------------------------------

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_names[var.cluster_name]
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "ecr_repository_url" {
  description = "ECR repository URL for the API image"
  value       = module.ecr.repository_urls[var.ecr_repository_name]
}

output "configure_kubectl" {
  description = "Command to add the cluster to your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_names[var.cluster_name]}"
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoints[var.cluster_name]
}

output "cluster_version" {
  description = "EKS Kubernetes version"
  value       = module.eks.cluster_versions[var.cluster_name]
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_ids[local.vpc_key]
}

output "public_subnet_ids" {
  description = "Public subnet IDs (worker nodes)"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS control plane ENIs)"
  value       = module.subnets.private_subnet_ids
}

output "irsa_role_arns" {
  description = "IRSA role ARNs"
  value       = module.irsa.role_arns
}

output "addon_versions" {
  description = "Installed EKS add-on versions"
  value       = module.addons.addon_versions
}
