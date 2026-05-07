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
  #   key            = "serverless-api/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "api" {
  source = "../../modules/serverless-api"

  # CHANGE THIS — used as the Lambda function name and prefix for the IAM role / log group.
  name = "blueprints-api"

  # Leave as null to use the built-in "Hello from Lambda" handler.
  # When you have your own code:
  #   lambda_zip_path = "${path.module}/dist/lambda.zip"
  #   handler         = "app.handler"
  lambda_zip_path = null

  runtime     = "nodejs20.x"
  memory_size = 128
  timeout     = 10

  environment_variables = {
    STAGE = "dev"
    # Add your app's env vars here.
  }

  # Set to ["https://your-frontend.example.com"] in production instead of "*".
  cors_allow_origins = ["*"]

  tags = {
    Project   = "blueprints"
    Example   = "serverless-api"
    ManagedBy = "terraform"
  }
}

output "api_endpoint" {
  description = "Base URL — curl this to test the API."
  value       = module.api.api_endpoint
}

output "log_group_name" {
  value = module.api.log_group_name
}
