#---------------------------------------------------------------------------------------------
# Terraform Configuration for Route Table Associations
#---------------------------------------------------------------------------------------------

locals {
  associations = merge([
    for rt_key, rt in var.route_tables : {
      for subnet_key in rt.subnet_keys :
      "${rt_key}-${subnet_key}" => {
        route_table_key = rt_key
        subnet_key      = subnet_key
      }
    }
  ]...)
}

resource "aws_route_table_association" "this" {
  for_each = local.associations

  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.this[each.value.route_table_key].id
}
