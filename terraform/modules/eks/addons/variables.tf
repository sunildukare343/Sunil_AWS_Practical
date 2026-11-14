variable "addons" {
  type = map(object({
    cluster_name = string
    addon_name   = string

    addon_version = optional(string)

    # Key of an IRSA role in var.irsa_role_arns to use as the add-on's service account role
    irsa_role_key = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    preserve_on_delete = optional(bool, true)

    pod_identity_associations = optional(list(object({
      role_arn    = string
      service_account = string
    })), [])

    tags = optional(map(string), {})
  }))
  description = "A map of EKS addons, where the key is a unique identifier for the addon and the value is an object containing its configuration."
}

variable "irsa_role_arns" {
  type        = map(string)
  description = "IRSA role ARNs keyed by role key (from the IRSA module), referenced by addons[*].irsa_role_key"
  default     = {}
}
