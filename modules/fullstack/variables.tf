variable "name" {
  description = "Name prefix for all resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

# ---------- App / ECS ----------
variable "container_name" {
  description = "Container name in the ECS task definition."
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Docker image including tag."
  type        = string
  default     = "nginx:alpine"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Plain env vars for the container (DB credentials are injected as secrets)."
  type        = map(string)
  default     = {}
}

variable "task_cpu" {
  description = "Fargate CPU units."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running tasks."
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/"
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 7
}

variable "deregistration_delay" {
  description = "Seconds the ALB waits before deregistering a target. Lower = faster destroys/deploys. AWS default is 300; we use 30 for demo speed. Bump back up for production."
  type        = number
  default     = 30
}

# ---------- RDS ----------
variable "db_engine" {
  description = "RDS engine. postgres or mysql are typical."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "RDS engine version. Pick one currently supported by AWS in your region. Check with: aws rds describe-db-engine-versions --engine postgres --region <region> --query 'DBEngineVersions[].EngineVersion'"
  type        = string
  default     = "16.13"
}

variable "db_instance_class" {
  description = "RDS instance class. db.t4g.micro is the cheapest current-gen option."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB. Minimum 20 for gp3."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name created on the instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username. The password is auto-generated and stored in Secrets Manager."
  type        = string
  default     = "appuser"
}

variable "db_port" {
  description = "DB port. 5432 for postgres, 3306 for mysql."
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Whether to deploy a standby in a second AZ. Doubles the DB cost."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Set to true for demos to avoid leftover snapshots costing money."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Block accidental DB deletion. Set to true for production."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to keep automated backups (0 disables)."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
