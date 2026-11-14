#-----------------------------------------------------------------------------
# Main Terraform Configuration for Internet Gateway Module
#-----------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  for_each = var.internet_gateways

  vpc_id = var.vpc_ids[each.value.vpc_key]

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}
