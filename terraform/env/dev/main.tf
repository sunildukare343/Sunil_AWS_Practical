#-----------------------------------------------------------------------------
# Container Registry
#-----------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  repositories = {
    (var.ecr_repository_name) = {
      image_tag_mutability = "IMMUTABLE" # tags (commit SHA) can't be overwritten
      scan_on_push         = true
      force_delete         = var.ecr_force_delete
    }
  }
}