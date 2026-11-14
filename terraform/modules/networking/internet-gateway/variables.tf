#-----------------------------------------------------------------------------
# Variables for Internet Gateway Module
#-----------------------------------------------------------------------------

variable "vpc_ids" {
  type        = map(string)
  description = "IDs of all VPCs from remote state"
}

variable "internet_gateways" {
  type = map(object({
    vpc_key = string
    tags    = optional(map(string), {})
  }))
  description = "Configuration for Internet Gateways, including associated VPC"
}
