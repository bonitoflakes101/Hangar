variable "name" {
  description = "Name prefix used for the Lambda, API, log group, and IAM role."
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to a .zip containing your Lambda code. If null, the module ships a tiny default 'Hello from Lambda' handler so you can test the wiring end to end."
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda handler in <file>.<exportedFunction> form. Default matches the bundled index.js."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime. nodejs20.x is the current LTS as of 2025."
  type        = string
  default     = "nodejs20.x"
}

variable "memory_size" {
  description = "Lambda memory in MB. CPU scales with memory."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Lambda timeout in seconds (max 900)."
  type        = number
  default     = 10
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "cors_allow_origins" {
  description = "Origins allowed by API Gateway CORS. ['*'] for fully public, otherwise list specific origins."
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention for /aws/lambda/<name>."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
