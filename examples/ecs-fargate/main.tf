terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # ----- Remote state (recommended for teams) -----
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "ecs-fargate/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "app" {
  source = "../../modules/ecs-fargate"

  # CHANGE THIS — used as a prefix for the cluster, ALB, log group, IAM roles, etc.
  name = "blueprints-demo"

  # Default image is nginx:alpine, which works out of the box.
  # Replace with your own image (e.g. "1234567890.dkr.ecr.ap-southeast-1.amazonaws.com/my-app:v1")
  # once you push one.
  container_image = "nginx:alpine"
  container_port  = 80

  # 1 task = single point of failure but cheapest. Bump to 2+ for real workloads.
  desired_count = 1

  # Smallest Fargate sizing. Increase if your app needs more.
  task_cpu    = 256
  task_memory = 512

  # ALB target group health check — change to /healthz or whatever your app exposes.
  health_check_path = "/"

  container_environment = {
    LOG_LEVEL = "info"
    # Add your app's env vars here.
  }

  tags = {
    Project   = "blueprints"
    Example   = "ecs-fargate"
    ManagedBy = "terraform"
  }
}

output "alb_url" {
  description = "Open this URL in a browser after apply finishes."
  value       = module.app.alb_url
}

output "log_group_name" {
  value = module.app.log_group_name
}
