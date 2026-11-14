data "aws_iam_policy_document" "assume_role" {
  for_each = var.irsa_roles

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arns[each.value.oidc_provider_arn_key]]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_provider_urls[each.value.oidc_provider_url_key], "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_provider_urls[each.value.oidc_provider_url_key], "https://", "")}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.irsa_roles

  name                 = coalesce(try(each.value.role_name, null), each.key)
  assume_role_policy   = data.aws_iam_policy_document.assume_role[each.key].json
  max_session_duration = try(each.value.max_session_duration, 3600)
  description          = try(each.value.description, "IRSA role for ${each.value.namespace}/${each.value.service_account}")

  tags = merge({
    "ServiceAccount" = "${each.value.namespace}/${each.value.service_account}"
    "Cluster"        = try(each.value.cluster_name, "unknown")
  }, each.value.tags)
}

# Policy Attachments
locals {
  policy_attachments = merge([
    for role_key, role in var.irsa_roles : {
      for idx, policy_arn in coalesce(role.policy_arns, []) :
      "${role_key}-${idx}" => {
        role_key   = role_key
        policy_arn = policy_arn
      }
    }
  ]...)
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.policy_attachments

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}