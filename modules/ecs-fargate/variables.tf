variable "name" {
  description = "Short name used as a prefix for all resources (cluster, ALB, log group, etc.)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. /16 gives plenty of room."
  type        = string
  default     = "10.10.0.0/16"
}

variable "container_name" {
  description = "Name used inside the ECS task definition for the container."
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Docker image to run, including tag. Use a public image (e.g. nginx:alpine) or a private ECR image — the task execution role can pull from ECR by default."
  type        = string
  default     = "nginx:alpine"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Environment variables passed to the container as a map."
  type        = map(string)
  default     = {}
}

variable "task_cpu" {
  description = "Fargate task CPU units. 256 = 0.25 vCPU. Valid values: 256, 512, 1024, 2048, 4096."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB. Must be compatible with task_cpu (see AWS docs)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running tasks. 1 is fine for a demo; production should be >= 2 across AZs."
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "HTTP path the ALB target group uses to check task health."
  type        = string
  default     = "/"
}

variable "log_retention_days" {
  description = "How long to keep container logs in CloudWatch."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
