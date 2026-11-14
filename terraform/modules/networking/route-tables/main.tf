#---------------------------------------------------------------------------------------------
# Main Terraform Configuration for Route Tables Module  
#---------------------------------------------------------------------------------------------

resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = var.vpc_ids[each.value.vpc_key]

  dynamic "route" {
    for_each = each.value.route_type == "public" ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = var.igw_ids[each.value.igw_key]
    }
  }

  dynamic "route" {
    # No NAT key -> private subnet has no internet route (lab: no NAT gateway)
    for_each = each.value.route_type == "private" && each.value.nat_key != null ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.nat_gateway_ids[each.value.nat_key]
    }
  }

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}
