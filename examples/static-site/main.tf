terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # ----- Remote state (recommended for teams) -----
  # Uncomment after creating the bucket and DynamoDB table once by hand.
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"            # globally unique
  #   key            = "static-site/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-locks"               # for state locking
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "ap-southeast-1" # Singapore — change to your nearest region if you prefer
}

module "site" {
  source = "../../modules/static-site"

  # CHANGE THIS — bucket names are globally unique across every AWS account.
  # Add your username + a date so you don't collide with someone else.
  bucket_name = "blueprints-static-site-terraform-admin-20260507"

  # If you upload a built React/Vue app, set this to true so refreshing
  # /some/route still serves index.html instead of returning 403.
  spa_mode = false

  # Cheapest price class — only US/Europe edge locations.
  # Use PriceClass_All if you have global users.
  price_class = "PriceClass_100"

  tags = {
    Project   = "blueprints"
    Example   = "static-site"
    ManagedBy = "terraform"
  }
}

output "bucket_id" {
  value = module.site.bucket_id
}

output "cloudfront_url" {
  value = module.site.cloudfront_url
}

output "cloudfront_distribution_id" {
  value = module.site.cloudfront_distribution_id
}
