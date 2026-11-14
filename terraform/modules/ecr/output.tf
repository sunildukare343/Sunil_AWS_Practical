#-----------------------------------------------------------------------------
# Outputs for ECR Module
#-----------------------------------------------------------------------------

output "repository_arns" {
  value = {
    for k, repo in aws_ecr_repository.this : k => repo.arn
  }
  description = "ARNs of all ECR repositories"
}

output "repository_urls" {
  value = {
    for k, repo in aws_ecr_repository.this : k => repo.repository_url
  }
  description = "URLs of all ECR repositories"
}

output "repository_names" {
  value = {
    for k, repo in aws_ecr_repository.this : k => repo.name
  }
  description = "Names of all ECR repositories"
}
