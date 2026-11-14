#---------------------------------------------------------------------------------------------
# Main Terraform Configuration for Subnets Module
#---------------------------------------------------------------------------------------------

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = var.vpc_ids[each.value.vpc_key]
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  map_public_ip_on_launch = each.value.subnet_type == "public"

  tags = merge(
    {
      Name       = each.key
      SubnetType = each.value.subnet_type
    },
    each.value.tags
  )
}
