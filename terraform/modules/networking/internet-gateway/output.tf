#-----------------------------------------------------------------------------
# Outputs for Internet Gateway Module
#-----------------------------------------------------------------------------

output "igw_ids" {
  value = {
    for k, igw in aws_internet_gateway.this : k => igw.id
  }
  description = "IDs of all Internet Gateways"
}
