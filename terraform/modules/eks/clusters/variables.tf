variable "subnet_ids" {
  type        = map(string)
  description = "A map of subnet IDs, where the key is a unique identifier for the subnet and the value is the actual subnet ID."
}

variable "vpc_ids" {
  type        = map(string)
  description = "A map of VPC IDs, where the key is a unique identifier for the VPC and the value is the actual VPC ID."
}

variable "security_group_ids" {
  type        = map(string)
  description = "A map of security group IDs, where the key is a unique identifier for the security group and the value is the actual security group ID."
}

variable "eks_clusters" {
  type = map(object({
    vpc_key                       = string
    version                       = string
    subnet_keys                   = list(string)
    bootstrap_self_managed_addons = optional(bool, false)

    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, false)
    # CIDRs allowed to reach the public API endpoint (only used when endpoint_public_access = true)
    public_access_cidrs = optional(list(string), [])

    cluster_log_types = optional(list(string), [
      "api",
      "audit",
      "authenticator"
    ])

    authentication_mode = optional(string, "API_AND_CONFIG_MAP")

    security_group_keys = list(string)

    log_retention_days = optional(number, 7)

    tags = optional(map(string), {})

    managed_node_groups = optional(map(object({
      subnet_keys    = optional(list(string))
      instance_types = list(string)

      capacity_type = optional(string, "ON_DEMAND")

      desired_size = number
      min_size     = number
      max_size     = number

      disk_size = optional(number, 20)

      labels = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])

      tags = optional(map(string), {})
    })), {})
  }))
  description = "A map of EKS clusters, where the key is a unique identifier for the cluster and the value is an object containing its configuration."
}
