#-----------------------------------------------------------------------------
# Outputs for VPC Endpoints Module
#-----------------------------------------------------------------------------

output "s3_endpoint_ids" {
  value       = { for k, v in aws_vpc_endpoint.s3 : k => v.id }
  description = "IDs of S3 gateway endpoints"
}

output "s3_endpoint_arns" {
  value       = { for k, v in aws_vpc_endpoint.s3 : k => v.arn }
  description = "ARNs of S3 gateway endpoints"
}
