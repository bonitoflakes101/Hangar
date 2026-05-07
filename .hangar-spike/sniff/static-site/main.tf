terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "main" {
  source = "/Users/xiang/Documents/GitHub/Hangar/modules/static-site"

  bucket_name = "hangar-spike-static-267860592610"
  spa_mode    = false
  price_class = "PriceClass_100"

  tags = {
    ManagedBy   = "hangar"
    Stack       = "spike-static-site"
    Owner       = "xiang"
    Environment = "sandbox"
  }
}

output "bucket_id"                  { value = module.main.bucket_id }
output "cloudfront_url"             { value = module.main.cloudfront_url }
output "cloudfront_distribution_id" { value = module.main.cloudfront_distribution_id }
