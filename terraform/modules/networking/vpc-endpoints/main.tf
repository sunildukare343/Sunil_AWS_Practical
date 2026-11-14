#-----------------------------------------------------------------------------
# Main Terraform Configuration for VPC Endpoints Module
#-----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  for_each = var.s3_endpoints

  vpc_id            = var.vpc_ids[each.value.vpc_key]
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt_key in each.value.route_table_keys : var.route_table_ids[rt_key]]

  tags = merge(
    {
      Name = "${each.key}"
    },
    each.value.tags
  )
}

