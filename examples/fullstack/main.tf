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
  #   key            = "fullstack/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "stack" {
  source = "../../modules/fullstack"

  # CHANGE THIS — used as a prefix for the cluster, ALB, RDS instance, secret, IAM roles, log group.
  # Keep it short (RDS identifiers can't be too long) and lowercase-with-hyphens.
  name = "blueprints-fs"

  # Adminer is a tiny public DB admin UI. It proves the whole path works:
  # browser -> ALB -> ECS task -> RDS. After deploy, open the ALB URL, log in
  # with the RDS credentials, and you can run real SQL against your database.
  # Swap to your own image (e.g. an ECR URI) when you have one to deploy.
  container_image = "adminer:latest"
  container_port  = 8080 # adminer listens on 8080
  desired_count   = 1
  task_cpu        = 256
  task_memory     = 512

  # Adminer pre-fills the System/Server fields when these env vars are set,
  # so you only need to type the username/password on the login page.
  container_environment = {
    ADMINER_DEFAULT_SERVER = "" # set after first apply if you want it pre-filled
    ADMINER_DESIGN         = "dracula"
  }

  health_check_path = "/"

  # ----- Database -----
  db_engine            = "postgres"
  db_engine_version    = "16.13"     # Latest 16.x in ap-southeast-1 as of 2026-05
  db_instance_class    = "db.t4g.micro" # Cheapest current-gen
  db_allocated_storage = 20          # gp3 minimum
  db_name              = "appdb"     # Initial database created on the instance
  db_username          = "appuser"   # Master username (password is auto-generated)
  db_port              = 5432

  # Demo settings: don't keep snapshots/backups around when you destroy.
  # Flip these for production.
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = {
    Project   = "blueprints"
    Example   = "fullstack"
    ManagedBy = "terraform"
  }
}

output "alb_url" {
  description = "Open this URL after apply finishes."
  value       = module.stack.alb_url
}

output "db_endpoint" {
  description = "RDS endpoint — only reachable from inside the app security group."
  value       = module.stack.db_endpoint
}

output "db_secret_name" {
  description = "Read with: aws secretsmanager get-secret-value --secret-id <name>"
  value       = module.stack.db_secret_name
}

output "log_group_name" {
  value = module.stack.log_group_name
}
