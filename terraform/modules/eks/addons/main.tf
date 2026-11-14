resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name = each.value.cluster_name
  addon_name   = each.value.addon_name

  addon_version               = try(each.value.addon_version, null)
  service_account_role_arn    = each.value.irsa_role_key != null ? var.irsa_role_arns[each.value.irsa_role_key] : null
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, each.value.resolve_conflicts_on_create)
  preserve                    = try(each.value.preserve_on_delete, true)

  dynamic "pod_identity_association" {
    for_each = try(each.value.pod_identity_associations, [])
    content {
      role_arn        = pod_identity_association.value.role_arn
      service_account = pod_identity_association.value.service_account
    }
  }

  tags = merge(
    {
      Name = "${each.key}-addon"
    },
    each.value.tags
  )
}
