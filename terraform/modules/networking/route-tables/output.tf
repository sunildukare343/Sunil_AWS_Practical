#-----------------------------------------------------------------------------
# Outputs for Route Tables Module
#-----------------------------------------------------------------------------

output "route_table_ids" {
  value = {
    for k, rt in aws_route_table.this : k => rt.id
  }
  description = "IDs of all route tables"
}
