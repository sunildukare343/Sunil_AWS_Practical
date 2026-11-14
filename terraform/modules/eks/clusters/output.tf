# OIDC Provider ARN Output
output "cluster_oidc_provider_arn" {
  description = "Map of cluster name to OIDC Provider ARN"
  value = {
    for k, provider in aws_iam_openid_connect_provider.this : k => provider.arn
  }
}

# OIDC Provider URL Output
output "cluster_oidc_provider_url" {
  description = "Map of cluster name to OIDC Provider URL"
  value = {
    for k, provider in aws_iam_openid_connect_provider.this : k => provider.url
  }
}

output "cluster_names" {
  description = "EKS cluster names"
  value = {
    for k, cluster in aws_eks_cluster.this : k => cluster.name
  }
}

output "cluster_endpoints" {
  description = "EKS cluster API endpoints"
  value = {
    for k, cluster in aws_eks_cluster.this : k => cluster.endpoint
  }
}

# output "cluster_ca" {
#   description = "EKS cluster certificate authority data"
#   value = {
#     for k, cluster in aws_eks_cluster.this :
#     k => cluster.certificate_authority[0].data
#   }
#   sensitive = true
# }

# output "cluster_oidc_issuer" {
#   description = "EKS cluster OIDC provider issuer URL"
#   value = {
#     for k, cluster in aws_eks_cluster.this :
#     k => cluster.identity[0].oidc[0].issuer
#   }
# }

output "cluster_versions" {
  description = "EKS cluster Kubernetes versions"
  value = {
    for k, cluster in aws_eks_cluster.this : k => cluster.version
  }
}

# output "cluster_role_arns" {
#   description = "ARN of cluster IAM roles"
#   value = {
#     for k, role in aws_iam_role.cluster : k => role.arn
#   }
# }

# output "kms_key_ids" {
#   description = "KMS key IDs for cluster encryption"
#   value = {
#     for k, key in aws_kms_key.cluster : k => key.id
#   }
# }

# output "kms_key_arns" {
#   description = "KMS key ARNs for cluster encryption"
#   value = {
#     for k, key in aws_kms_key.cluster : k => key.arn
#   }
# }

# output "cloudwatch_log_group_names" {
#   description = "CloudWatch log group names for EKS cluster logs"
#   value = {
#     for k, lg in aws_cloudwatch_log_group.cluster : k => lg.name
#   }
# }

# output "node_group_arns" {
#   description = "ARNs of EKS node groups"
#   value = {
#     for k, ng in aws_eks_node_group.this : k => ng.arn
#   }
# }

output "node_group_statuses" {
  description = "Status of EKS node groups"
  value = {
    for k, ng in aws_eks_node_group.this : k => ng.status
  }
}

# output "node_role_arns" {
#   description = "ARNs of node IAM roles"
#   value = {
#     for k, role in aws_iam_role.node : k => role.arn
#   }
# }
