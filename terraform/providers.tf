terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Required for WAF (CloudFront scope) and ACM certificates — both must be us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
