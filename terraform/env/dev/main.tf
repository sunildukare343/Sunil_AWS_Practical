#-----------------------------------------------------------------------------
# DEV Environment - Root Module
#
# All modules are called from this single root -> ONE state file.
# Module outputs are passed directly to the next module.
#
# Lab design (see assignment brief):
#   - 2 AZs: 2 public + 2 private subnets
#   - EKS control plane ENIs in the private subnets
#   - Worker node(s) in the public subnets (no NAT gateway -> lower cost).
#     Inbound to nodes is only from the EKS cluster security group; no SSH.
#     Production alternative: nodes in private subnets + NAT gateway (set
#     nat_gateways and nat_key in tfvars) or VPC interface endpoints.
#   - EKS API: public endpoint restricted to admin CIDRs + private endpoint on
#   - Add-ons: vpc-cni, kube-proxy, coredns, aws-ebs-csi-driver (with IRSA)
#-----------------------------------------------------------------------------

locals {
  vpc_key = one(keys(var.vpcs))

  public_subnet_keys  = sort([for k, s in var.subnets : k if s.subnet_type == "public"])
  private_subnet_keys = sort([for k, s in var.subnets : k if s.subnet_type == "private"])

  # EKS cluster built from simple variables (cluster name, version, node size)
  eks_clusters = {
    (var.cluster_name) = {
      vpc_key     = local.vpc_key
      version     = var.kubernetes_version
      subnet_keys = local.private_subnet_keys # control plane ENIs

      endpoint_private_access = true
      endpoint_public_access  = true
      public_access_cidrs     = var.cluster_public_access_cidrs

      # Installs default vpc-cni/kube-proxy/coredns so nodes can join; the
      # managed add-ons below then take them over (OVERWRITE).
      bootstrap_self_managed_addons = true

      cluster_log_types   = ["api", "audit", "authenticator"]
      log_retention_days  = var.log_retention_days
      authentication_mode = "API_AND_CONFIG_MAP"
      security_group_keys = var.cluster_security_group_keys

      managed_node_groups = {
        default = {
          subnet_keys    = local.public_subnet_keys
          instance_types = [var.node_instance_type]
          capacity_type  = var.node_capacity_type
          desired_size   = var.node_desired_size
          min_size       = var.node_min_size
          max_size       = var.node_max_size
          disk_size      = var.node_disk_size
          labels         = { Workload = "general" }
        }
      }
    }
  }

  # IRSA roles for add-ons that call AWS APIs
  irsa_roles = {
    vpc-cni = {
      oidc_provider_arn_key = var.cluster_name
      oidc_provider_url_key = var.cluster_name
      namespace             = "kube-system"
      service_account       = "aws-node"
      role_name             = "${var.cluster_name}-vpc-cni"
      description           = "IRSA for Amazon VPC CNI"
      policy_arns           = ["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]
    }

    ebs-csi = {
      oidc_provider_arn_key = var.cluster_name
      oidc_provider_url_key = var.cluster_name
      namespace             = "kube-system"
      service_account       = "ebs-csi-controller-sa"
      role_name             = "${var.cluster_name}-ebs-csi"
      description           = "IRSA for Amazon EBS CSI driver"
      policy_arns           = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
    }
  }

  # Networking/DNS add-ons + EBS CSI driver (PostgreSQL PVC storage)
  addons = {
    vpc-cni = {
      cluster_name  = var.cluster_name
      addon_name    = "vpc-cni"
      addon_version = lookup(var.addon_versions, "vpc-cni", null)
      irsa_role_key = "vpc-cni"
    }
    kube-proxy = {
      cluster_name  = var.cluster_name
      addon_name    = "kube-proxy"
      addon_version = lookup(var.addon_versions, "kube-proxy", null)
    }
    coredns = {
      cluster_name  = var.cluster_name
      addon_name    = "coredns"
      addon_version = lookup(var.addon_versions, "coredns", null)
    }
    aws-ebs-csi-driver = {
      cluster_name  = var.cluster_name
      addon_name    = "aws-ebs-csi-driver"
      addon_version = lookup(var.addon_versions, "aws-ebs-csi-driver", null)
      irsa_role_key = "ebs-csi"
    }
  }
}

#-----------------------------------------------------------------------------
# Networking
#-----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/networking/vpc"

  vpcs = var.vpcs
}

module "subnets" {
  source = "../../modules/networking/subnets"

  vpc_ids = module.vpc.vpc_ids
  subnets = var.subnets
}

module "internet_gateway" {
  source = "../../modules/networking/internet-gateway"

  vpc_ids           = module.vpc.vpc_ids
  internet_gateways = var.internet_gateways
}

# Creates nothing while var.nat_gateways is empty (lab default).
module "nat_gateway" {
  source = "../../modules/networking/nat-gateway"

  vpc_ids      = module.vpc.vpc_ids
  nat_gateways = var.nat_gateways

  # A public NAT gateway needs the IGW attached to the VPC first.
  depends_on = [module.internet_gateway]
}

module "route_tables" {
  source = "../../modules/networking/route-tables"

  vpc_ids         = module.vpc.vpc_ids
  subnet_ids      = module.subnets.subnet_ids
  igw_ids         = module.internet_gateway.igw_ids
  nat_gateway_ids = module.nat_gateway.nat_gateway_ids
  route_tables    = var.route_tables
}

module "security_groups" {
  source = "../../modules/networking/security-groups"

  vpc_ids         = module.vpc.vpc_ids
  security_groups = var.security_groups
}

module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  aws_region      = var.aws_region
  vpc_ids         = module.vpc.vpc_ids
  route_table_ids = module.route_tables.route_table_ids
  s3_endpoints    = var.s3_endpoints
}

#-----------------------------------------------------------------------------
# Container Registry
#-----------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  repositories = {
    (var.ecr_repository_name) = {
      image_tag_mutability = "IMMUTABLE" # tags (commit SHA) can't be overwritten
      scan_on_push         = true
      force_delete         = var.ecr_force_delete
    }
  }
}

#-----------------------------------------------------------------------------
# EKS
#-----------------------------------------------------------------------------

module "eks" {
  source = "../../modules/eks/clusters"

  vpc_ids            = module.vpc.vpc_ids
  subnet_ids         = module.subnets.subnet_ids # control plane: private, nodes: public
  security_group_ids = module.security_groups.security_group_ids
  eks_clusters       = local.eks_clusters

  # Public subnets must have their IGW route before nodes try to join.
  depends_on = [module.route_tables]
}

module "irsa" {
  source = "../../modules/eks/irsa"

  cluster_oidc_provider_arns = module.eks.cluster_oidc_provider_arn
  cluster_oidc_provider_urls = module.eks.cluster_oidc_provider_url
  irsa_roles                 = local.irsa_roles
}

module "addons" {
  source = "../../modules/eks/addons"

  addons         = local.addons
  irsa_role_arns = module.irsa.role_arns

  # Add-ons reference the cluster by name, so wait for cluster + node group.
  depends_on = [module.eks]
}
