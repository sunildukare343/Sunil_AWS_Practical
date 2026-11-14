output "role_arns" {
  description = "ARNs of IRSA roles"
  value = {
    for k, role in aws_iam_role.this : k => role.arn
  }
}

output "role_names" {
  description = "Names of IRSA roles"
  value = {
    for k, role in aws_iam_role.this : k => role.name
  }
}

output "role_ids" {
  description = "IDs of IRSA roles"
  value = {
    for k, role in aws_iam_role.this : k => role.id
  }
}
