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
  source = "/Users/xiang/Documents/GitHub/Hangar/modules/fullstack"

  name = "hangar-spike-full"

  tags = {
    ManagedBy   = "hangar"
    Stack       = "spike-fullstack"
    Owner       = "xiang"
    Environment = "sandbox"
  }
}

output "alb_url"        { value = module.main.alb_url }
output "db_endpoint"    { value = module.main.db_endpoint }
output "db_secret_arn"  { value = module.main.db_secret_arn }
output "db_secret_name" { value = module.main.db_secret_name }
