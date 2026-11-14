#-----------------------------------------------------------------------------
# Variables for ECR Module
#-----------------------------------------------------------------------------

variable "repositories" {
  description = "ECR repositories"

  type = map(object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    force_delete         = optional(bool, false)
    tags                 = optional(map(string), {})
  }))
}
