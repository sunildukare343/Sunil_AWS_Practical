#-----------------------------------------------------------------------------
# Variables for NAT Gateway Module
#-----------------------------------------------------------------------------

variable "vpc_ids" {
  type        = map(string)
  description = "IDs of all VPCs from remote state"
}

variable "nat_gateways" {
  type = map(object({
    vpc_id_key = string
    # - auto mode   -> omit availability_zone_addresses or keep it empty
    # - manual mode -> provide availability_zone_addresses with specific AZs and EIP allocation IDs
    availability_zone_addresses = optional(map(object({
      availability_zone = string
      allocation_ids    = list(string)
    })), {})

    tags = optional(map(string), {})
  }))
  description = "Configuration for NAT Gateways"  
}
  