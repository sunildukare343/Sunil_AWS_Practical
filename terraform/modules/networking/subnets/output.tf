#---------------------------------------------------------------------------------------------
# Outputs for Subnets Module
#---------------------------------------------------------------------------------------------

output "subnet_ids" {
  value = {
    for k, subnet in aws_subnet.this : k => subnet.id
  }
  description = "IDs of all subnets"
}

output "public_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.this :
    k => subnet.id
    if var.subnets[k].subnet_type == "public"
  }
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.this :
    k => subnet.id
    if var.subnets[k].subnet_type == "private"
  }
  description = "IDs of private subnets"
}

output "isolated_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.this :
    k => subnet.id
    if var.subnets[k].subnet_type == "isolated"
  }
  description = "IDs of isolated subnets"
}
