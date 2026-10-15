# Remote State Backend (S3)
# ---------------------------------------------------------------
# The bucket name is intentionally NOT hardcoded here to avoid
# committing the AWS account ID to version control.
#
# Initialize with:
#   terraform init -backend-config=backend.hcl
#
# backend.hcl is gitignored and contains the bucket name.
# ---------------------------------------------------------------

terraform {
  backend "s3" {
    key            = "portfolio-site/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
