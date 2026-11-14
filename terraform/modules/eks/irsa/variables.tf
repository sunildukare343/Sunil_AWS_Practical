variable "irsa_roles" {
  description = "Map of IAM Roles for Service Accounts (IRSA) to create"
  type = map(object({
    # OIDC Configuration
    oidc_provider_arn_key = string
    oidc_provider_url_key = string

    # Kubernetes Service Account
    namespace       = string
    service_account = string

    # IAM Role Configuration
    role_name            = optional(string) # If not set, uses map key
    description          = optional(string, null)
    max_session_duration = optional(number, 3600) # 1 hour default

    # Policies
    policy_arns = optional(list(string), []) # Managed policy ARNs

    # Optional inline policy (JSON string)
    inline_policy_json = optional(string, null)

    # Additional trust conditions (advanced use cases)
    extra_conditions = optional(map(object({
      test     = string
      variable = string
      values   = list(string)
    })), {})

    # Tagging
    tags = optional(map(string), {})
  }))

  default = {}
}

variable "cluster_oidc_provider_arns" {
  type = map(string)
}

variable "cluster_oidc_provider_urls" {
  type = map(string)
}