#---------------------------------------------------------------------------------------------
# Variables for Subnets Module
#---------------------------------------------------------------------------------------------  

variable "vpc_ids" {
  description = "Map of VPC IDs from remote state"
  type        = map(string)
}

variable "subnets" {
  type = map(object({
    vpc_key           = string
    cidr_block        = string
    availability_zone = string
    subnet_type       = string
    tags              = optional(map(string), {})
  }))
  description = "Configuration for subnets, including associated VPC and subnet type  (public/private)"
}
