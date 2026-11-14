#-----------------------------------------------------------------------------
# Main Terraform Configuration for ECR Module
#-----------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = each.key
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}
