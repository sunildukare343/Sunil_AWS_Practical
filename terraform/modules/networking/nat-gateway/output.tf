#-----------------------------------------------------------------------------
# Outputs for NAT Gateway Module
#-----------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "Regional NAT gateway IDs keyed by nat gateway name"

  value = {
    for k, nat in aws_nat_gateway.regional :
    k => nat.id
  }
}
