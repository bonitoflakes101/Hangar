output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB lives here)."
  value       = [for s in aws_subnet.public : s.id]
}

output "app_subnet_ids" {
  description = "Private app subnet IDs (ECS tasks)."
  value       = [for s in aws_subnet.private_app : s.id]
}

output "db_subnet_ids" {
  description = "Private DB subnet IDs (RDS)."
  value       = [for s in aws_subnet.private_db : s.id]
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Full http:// URL of the ALB."
  value       = "http://${aws_lb.this.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "log_group_name" {
  description = "CloudWatch log group for app container logs."
  value       = aws_cloudwatch_log_group.app.name
}

output "db_endpoint" {
  description = "RDS endpoint (host:port). Reachable only from the app security group."
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "RDS hostname (no port)."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB credentials JSON."
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "Secrets Manager secret name. Read with: aws secretsmanager get-secret-value --secret-id <name>"
  value       = aws_secretsmanager_secret.db.name
}
