#-----------------------------------------------------------------------------
# Outputs for VPC Module
#-----------------------------------------------------------------------------

output "vpc_ids" {
  description = "VPC IDs"
  value = {
    for k, v in aws_vpc.this : k => v.id
  }
}

output "vpc_cidrs" {
  description = "VPC CIDR blocks"
  value = {
    for k, v in aws_vpc.this : k => v.cidr_block
  }
}
