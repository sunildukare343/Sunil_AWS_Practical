#-----------------------------------------------------------------------------
# Variables for Route Tables Module
#-----------------------------------------------------------------------------

variable "vpc_ids" {
  type        = map(string)
  description = "IDs of all VPCs from remote state"
}

variable "igw_ids" {
  type        = map(string)
  description = "IDs of all Internet Gateways from remote state"
}

variable "nat_gateway_ids" {
  type        = map(string)
  description = "IDs of all NAT Gateways (empty map when no NAT gateway is used)"
  default     = {}
}

variable "subnet_ids" {
  type        = map(string)
  description = "IDs of all subnets from remote state"
}


variable "route_tables" {
  type = map(object({
    vpc_key     = string
    route_type  = string
    igw_key     = optional(string)
    nat_key     = optional(string)
    subnet_keys = list(string)
    tags        = optional(map(string), {})
  }))
  description = "Configuration for route tables, including associated subnets and routes"
}

