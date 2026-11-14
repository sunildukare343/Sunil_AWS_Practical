#-----------------------------------------------------------------------------
# DEV Environment - Values
#-----------------------------------------------------------------------------

aws_region = "us-east-1"

tags = {
  Environment = "dev"
  Project     = "ae-fbc"
  Owner       = "sunil"
  ManagedBy   = "Terraform"
}

#--------------------------- EKS ---------------------------------------------

cluster_name       = "fbc-eks-dev-use1"
kubernetes_version = "1.35" # EKS standard support until 27 Mar 2027

# REPLACE with your public IP (curl -s https://checkip.amazonaws.com)/32
# 152.57.252.89 is a documentation placeholder and will lock you out.
cluster_public_access_cidrs = ["152.57.252.89/32"]

cluster_security_group_keys = ["fbc-sg-eks-cluster-dev-use1"]

# One node, not highly available (acceptable for this lab).
# t3.large = up to 35 pods; t3.medium (17 pods) is too tight for
# system add-ons + Argo CD + API + PostgreSQL.
node_instance_type = "t3.large"
node_capacity_type = "ON_DEMAND"
node_desired_size  = 1
node_min_size      = 1
node_max_size      = 2
node_disk_size     = 20

log_retention_days = 7

# Optional: pin add-on versions after checking
#   aws eks describe-addon-versions --kubernetes-version 1.35 --addon-name <name>

addon_versions = {
  vpc-cni            = "v1.23.2-eksbuild.8"
  coredns            = "v1.14.7-eksbuild.22"
  kube-proxy         = "v1.35.3-eksbuild.62"
  aws-ebs-csi-driver = "v1.67.2-eksbuild.1"
}

#--------------------------- ECR ---------------------------------------------

ecr_repository_name = "fbc-consent-api-dev"
ecr_force_delete    = true # lab: allow destroy while images exist

#--------------------------- VPC ---------------------------------------------

vpcs = {
  fbc-vpc-dev-use1 = {
    cidr_block           = "10.10.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags                 = {}
  }
}

#--------------------------- Subnets: 2 public + 2 private (2 AZs) ----------

subnets = {
  fbc-public-subnet-dev-use1a = {
    vpc_key           = "fbc-vpc-dev-use1"
    cidr_block        = "10.10.0.0/24"
    availability_zone = "us-east-1a"
    subnet_type       = "public"
    tags              = { "kubernetes.io/role/elb" = "1" }
  }
  fbc-public-subnet-dev-use1b = {
    vpc_key           = "fbc-vpc-dev-use1"
    cidr_block        = "10.10.1.0/24"
    availability_zone = "us-east-1b"
    subnet_type       = "public"
    tags              = { "kubernetes.io/role/elb" = "1" }
  }

  fbc-private-subnet-dev-use1a = {
    vpc_key           = "fbc-vpc-dev-use1"
    cidr_block        = "10.10.10.0/24"
    availability_zone = "us-east-1a"
    subnet_type       = "private"
    tags              = { "kubernetes.io/role/internal-elb" = "1" }
  }
  fbc-private-subnet-dev-use1b = {
    vpc_key           = "fbc-vpc-dev-use1"
    cidr_block        = "10.10.11.0/24"
    availability_zone = "us-east-1b"
    subnet_type       = "private"
    tags              = { "kubernetes.io/role/internal-elb" = "1" }
  }
}

#--------------------------- Internet Gateway --------------------------------

internet_gateways = {
  fbc-igw-dev-use1 = {
    vpc_key = "fbc-vpc-dev-use1"
  }
}

#--------------------------- NAT Gateway -------------------------------------
# None for this lab (cost). Production example:
# nat_gateways = {
#   fbc-nat-dev-use1 = { vpc_id_key = "fbc-vpc-dev-use1" }
# }
# ...and set nat_key = "fbc-nat-dev-use1" on the private route table.

nat_gateways = {}

#--------------------------- Route Tables ------------------------------------

route_tables = {
  fbc-public-rt-dev-use1 = {
    vpc_key     = "fbc-vpc-dev-use1"
    route_type  = "public" # 0.0.0.0/0 -> IGW
    igw_key     = "fbc-igw-dev-use1"
    subnet_keys = ["fbc-public-subnet-dev-use1a", "fbc-public-subnet-dev-use1b"]
  }

  fbc-private-rt-dev-use1 = {
    vpc_key     = "fbc-vpc-dev-use1"
    route_type  = "private" # local VPC only (no nat_key -> no internet route)
    subnet_keys = ["fbc-private-subnet-dev-use1a", "fbc-private-subnet-dev-use1b"]
  }
}

#--------------------------- Security Groups ---------------------------------
# Additional SG on the EKS control plane ENIs. EKS also creates its own
# cluster SG, used by the managed nodes (node <-> control plane traffic only).
# No SSH and no database exposure to the internet.

security_groups = {
  fbc-sg-eks-cluster-dev-use1 = {
    vpc_key     = "fbc-vpc-dev-use1"
    description = "Additional EKS control plane SG - API access from inside the VPC"
    tags        = { Tier = "eks" }

    ingress_rules = [
      { description = "Kubernetes API from VPC", from_port = 443, to_port = 443, protocol = "tcp", cidr_ipv4 = "10.10.0.0/16" }
    ]

    egress_rules = [
      { description = "All outbound IPv4", protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
    ]
  }
}

#--------------------------- VPC Endpoints -----------------------------------

s3_endpoints = {
  fbc-s3-endpoint-dev-use1 = {
    vpc_key          = "fbc-vpc-dev-use1"
    route_table_keys = ["fbc-public-rt-dev-use1", "fbc-private-rt-dev-use1"]
  }
}
