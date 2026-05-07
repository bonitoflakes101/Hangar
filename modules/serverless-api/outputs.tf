output "lambda_function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN."
  value       = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution IAM role. Attach extra policies here if your function needs to call other AWS APIs."
  value       = aws_iam_role.lambda.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for the Lambda."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "api_id" {
  description = "API Gateway HTTP API ID."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base URL of the API Gateway HTTP API. Append paths to invoke routes."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_arn" {
  description = "ARN of the API Gateway HTTP API."
  value       = aws_apigatewayv2_api.this.arn
}
