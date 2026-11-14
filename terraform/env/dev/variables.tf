#-----------------------------------------------------------------------------
# DEV Environment - Variables
#-----------------------------------------------------------------------------

#--------------------------- General -----------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource (provider default_tags)"
  default     = {}
}

#--------------------------- EKS ---------------------------------------------

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version - must be in EKS standard support"
}

variable "cluster_public_access_cidrs" {
  type        = list(string)
  description = "Admin source CIDRs allowed to reach the public EKS API endpoint (e.g. your IP as x.x.x.x/32)"

  validation {
    condition     = length(var.cluster_public_access_cidrs) > 0 && !contains(var.cluster_public_access_cidrs, "0.0.0.0/0")
    error_message = "Provide at least one admin CIDR and do not open the EKS API to 0.0.0.0/0."
  }
}

variable "cluster_security_group_keys" {
  type        = list(string)
  description = "Keys from var.security_groups to attach to the EKS control plane ENIs"
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for the managed node group"
}

variable "node_capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 1
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 2
}

variable "node_disk_size" {
  type        = number
  description = "Worker node root volume size (GiB)"
  default     = 20
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch retention for EKS control plane logs"
  default     = 7
}

variable "addon_versions" {
  type        = map(string)
  description = "Optional pinned EKS add-on versions keyed by add-on name; unset = EKS default for the cluster version"
  default     = {}
}

#--------------------------- ECR ---------------------------------------------

variable "ecr_repository_name" {
  type        = string
  description = "ECR repository for the API image"
}

variable "ecr_force_delete" {
  type        = bool
  description = "Delete the repository even if it still contains images on terraform destroy"
  default     = false
}

#--------------------------- VPC ---------------------------------------------

variable "vpcs" {
  description = "VPCs keyed by name"
  type = map(object({
    cidr_block           = string
    enable_dns_support   = bool
    enable_dns_hostnames = bool
    tags                 = map(string)
  }))
}

variable "subnets" {
  description = "Subnets keyed by name (subnet_type: public / private)"
  type = map(object({
    vpc_key           = string
    cidr_block        = string
    availability_zone = string
    subnet_type       = string
    tags              = optional(map(string), {})
  }))
}

variable "internet_gateways" {
  description = "Internet gateways keyed by name"
  type = map(object({
    vpc_key = string
    tags    = optional(map(string), {})
  }))
}

variable "nat_gateways" {
  description = "Regional NAT gateways. Empty for this lab (no NAT); add one for production private nodes"
  type = map(object({
    vpc_id_key = string
    availability_zone_addresses = optional(map(object({
      availability_zone = string
      allocation_ids    = list(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "route_tables" {
  description = "Route tables (route_type: public = IGW route, private = NAT route only if nat_key is set)"
  type = map(object({
    vpc_key     = string
    route_type  = string
    igw_key     = optional(string)
    nat_key     = optional(string)
    subnet_keys = list(string)
    tags        = optional(map(string), {})
  }))
}

variable "security_groups" {
  description = "Security groups with ingress/egress rules"
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
}

variable "s3_endpoints" {
  description = "S3 gateway endpoints (free; keeps ECR layer/S3 traffic on the AWS network)"
  type = map(object({
    vpc_key          = string
    route_table_keys = list(string)
    tags             = optional(map(string), {})
  }))
  default = {}
}
