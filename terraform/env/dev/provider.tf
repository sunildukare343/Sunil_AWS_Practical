#-----------------------------------------------------------------------------
# Terraform & Provider Configuration - DEV
#
# Versions are constrained here; exact provider versions are pinned in
# .terraform.lock.hcl (created by `terraform init`) - commit that file.
#-----------------------------------------------------------------------------

terraform {
  # use_lockfile (S3 native state locking) needs Terraform >= 1.10
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.63"
    }

    # Used by the EKS cluster module to read the OIDC issuer thumbprint (IRSA)
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every taggable resource. Change one of these in the console to
  # demonstrate drift detection (terraform plan) and correction (terraform apply).
  default_tags {
    tags = var.tags
  }
}
