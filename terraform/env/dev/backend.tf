#-----------------------------------------------------------------------------
# Terraform Backend Configuration - DEV
#
# ONE remote state file for the whole dev environment, with S3 native locking.
#
# Create the bucket once, before `terraform init` (versioning protects state
# against accidental overwrite/delete; block public access; default encryption):
#   aws s3api create-bucket --bucket fbc-bucket-dev-tfstate-use1 --region us-east-1
#   aws s3api put-bucket-versioning --bucket fbc-bucket-dev-tfstate-use1 \
#     --versioning-configuration Status=Enabled
#   aws s3api put-public-access-block --bucket fbc-bucket-dev-tfstate-use1 \
#     --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
#
# Backend blocks cannot use variables - edit the values here directly.
#-----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket       = "test-one-bucket-250"
    key          = "ae-fbc/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3 native lock file (no DynamoDB table needed)
  }
}
