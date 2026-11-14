#---------------------------------------------------------------------------------------------
# Main Terraform Configuration for Security Groups Module
#---------------------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.key
  description = each.value.description
  vpc_id      = var.vpc_ids[each.value.vpc_key]

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}

locals {
  ingress_rules = merge([
    for sg_key, sg in var.security_groups : {
      for idx, rule in sg.ingress_rules :
      "${sg_key}-${idx}" => merge(rule, {
        security_group_key = sg_key
      })
    }
  ]...)

  egress_rules = merge([
    for sg_key, sg in var.security_groups : {
      for idx, rule in sg.egress_rules :
      "${sg_key}-${idx}" => merge(rule, {
        security_group_key = sg_key
      })
    }
  ]...)
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.this[each.value.security_group_key].id

  description = try(each.value.description, null)
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  cidr_ipv4 = try(each.value.cidr_ipv4, null)
  cidr_ipv6 = try(each.value.cidr_ipv6, null)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = aws_security_group.this[each.value.security_group_key].id

  description = try(each.value.description, null)
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)
  ip_protocol = each.value.protocol

  cidr_ipv4 = try(each.value.cidr_ipv4, null)
  cidr_ipv6 = try(each.value.cidr_ipv6, null)
}
