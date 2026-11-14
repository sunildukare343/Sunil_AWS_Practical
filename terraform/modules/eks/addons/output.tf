output "addon_arns" {
  description = "ARNs of the EKS add-ons"
  value = {
    for k, addon in aws_eks_addon.this : k => addon.arn
  }
}

output "addon_versions" {
  description = "Versions of the EKS add-ons"
  value = {
    for k, addon in aws_eks_addon.this : k => addon.addon_version
  }
}

output "addon_created_at" {
  description = "Creation timestamps of the EKS add-ons"
  value = {
    for k, addon in aws_eks_addon.this : k => addon.created_at
  }
}

output "addon_statuses" {
  description = "Health status of the EKS add-ons"
  value = {
    for k, addon in aws_eks_addon.this : k => try(addon.health[0].issues, null)
  }
}
