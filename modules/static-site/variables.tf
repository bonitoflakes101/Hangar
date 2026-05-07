variable "bucket_name" {
  description = "Globally unique S3 bucket name. S3 bucket names must be unique across ALL of AWS, not just your account."
  type        = string
}

variable "default_root_object" {
  description = "Object served when a viewer requests the root URL of the distribution (e.g. index.html)."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/Europe (cheapest), PriceClass_200 = + Asia, PriceClass_All = global."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "enable_versioning" {
  description = "Whether to enable S3 bucket versioning. Useful for rollback; slightly increases storage cost."
  type        = bool
  default     = false
}

variable "spa_mode" {
  description = "If true, CloudFront returns the root object for 403/404 responses. Enable for single-page apps (React, Vue, etc.) that handle routing client-side."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
