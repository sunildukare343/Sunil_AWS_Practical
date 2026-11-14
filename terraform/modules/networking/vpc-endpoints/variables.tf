#-----------------------------------------------------------------------------
# Variables for VPC Endpoints Module
#-----------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "The AWS region where the VPC endpoints will be created"
}

variable "vpc_ids" {
  type        = map(string)
  description = "Map of VPC keys to their IDs"
}

variable "route_table_ids" {
  type        = map(string)
  description = "Map of route table keys to their IDs"
}

variable "s3_endpoints" {
  type = map(object({
    vpc_key          = string
    route_table_keys = list(string)
    tags             = optional(map(string), {})
  }))
  description = "Configuration for S3 gateway endpoints"
  default     = {}
}
