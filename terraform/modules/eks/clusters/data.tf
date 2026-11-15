data "aws_eks_addon_version" "this" {
  for_each = var.eks_clusters

  addon_name         = "vpc-cni"
  kubernetes_version = each.value.version
  most_recent        = true
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
