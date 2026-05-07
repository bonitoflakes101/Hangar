output "vpc_id" {
  description = "ID of the VPC created by this module."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (where the ALB lives)."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where ECS tasks run)."
  value       = [for s in aws_subnet.private : s.id]
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB. Hit this URL with curl/browser to test the service."
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Full http:// URL of the ALB."
  value       = "http://${aws_lb.this.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "task_role_arn" {
  description = "ARN of the IAM role assumed by the running container (attach extra policies here for AWS API access from inside the app)."
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "CloudWatch log group containing container logs."
  value       = aws_cloudwatch_log_group.this.name
}
