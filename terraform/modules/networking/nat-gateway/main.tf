#-----------------------------------------------------------------------------
# Main Terraform Configuration for NAT Gateway Module
#-----------------------------------------------------------------------------

resource "aws_nat_gateway" "regional" {
  for_each = var.nat_gateways

  availability_mode = "regional"
  connectivity_type = "public"
  vpc_id            = var.vpc_ids[each.value.vpc_id_key]

  dynamic "availability_zone_address" {
    for_each = each.value.availability_zone_addresses

    content {
      availability_zone = availability_zone_address.value.availability_zone
      allocation_ids    = availability_zone_address.value.allocation_ids
    }
  }

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}