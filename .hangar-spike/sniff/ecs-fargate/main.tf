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
  source = "/Users/xiang/Documents/GitHub/Hangar/modules/ecs-fargate"

  name = "hangar-spike-ecs"

  tags = {
    ManagedBy   = "hangar"
    Stack       = "spike-ecs-fargate"
    Owner       = "xiang"
    Environment = "sandbox"
  }
}

output "alb_url"          { value = module.main.alb_url }
output "ecs_cluster_name" { value = module.main.ecs_cluster_name }
output "log_group_name"   { value = module.main.log_group_name }
