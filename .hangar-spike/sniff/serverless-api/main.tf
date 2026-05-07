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
  source = "/Users/xiang/Documents/GitHub/Hangar/modules/serverless-api"

  name = "hangar-spike-api"

  tags = {
    ManagedBy   = "hangar"
    Stack       = "spike-serverless-api"
    Owner       = "xiang"
    Environment = "sandbox"
  }
}

output "api_endpoint"        { value = module.main.api_endpoint }
output "lambda_function_name" { value = module.main.lambda_function_name }
output "log_group_name"      { value = module.main.log_group_name }
