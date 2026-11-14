#---------------------------------------------------------------------------------------------
# Variables for Security Groups Module
#---------------------------------------------------------------------------------------------  

variable "vpc_ids" {
  description = "IDs of all VPCs from remote state"
  type        = map(string)
}

variable "security_groups" {
  type = map(object({
    vpc_key     = string
    description = string
    tags        = optional(map(string), {})

    ingress_rules = optional(list(object({
      description = optional(string)
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_ipv4   = optional(string)
      cidr_ipv6   = optional(string)
    })), [])

    egress_rules = optional(list(object({
      description = optional(string)
      from_port   = optional(number)
      to_port     = optional(number)
      protocol    = string
      cidr_ipv4   = optional(string)
      cidr_ipv6   = optional(string)
    })), [])
  }))
  description = "Configuration for security groups, including associated VPC and rules"
}
