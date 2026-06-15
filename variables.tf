# Required

variable "name" {
  description = "Base name for all resources created by this module"
  type        = string
}

variable "image_uri" {
  description = "Full URI (including tag or digest) of the container image in ECR. Best Practice: use immutable tags over latest"
  type        = string
}

# Lambda vars

variable "lambda_timeout" {
  description = "Function timeout in seconds. The queue visibility timeout is derived from this (6x per AWS best practice)."
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Function memory in MB. CPU scales with memory."
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Plaintext environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "lambda_policy_arns" {
  description = "IAM policy ARNs to attach to the Lambda execution role for resources the applicaton code accesses"
  type        = list(string)
  default     = []
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions for the function. -1 means no reservation (account pool)."
  type        = number
  default     = -1
}

# Optional VPC - this enables lambda function to access resources in a private subnet

variable "vpc_subnet_ids" {
  description = <<-EOT
    Private subnet IDs to attach the function to. Leave null for default lambda behaviour.
    Only set this if the function must reach VPC-private resources.
    If the VPC-attached function also needs internet egress
    (Attaching lambda to public subnet does not give internet access inherently), the selected
    subnets must route outbound traffic through a NAT gateway or equivalent.
  EOT
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the function when vpc_subnet_ids is set."
  type        = list(string)
  default     = []
}

# Queue / event source

variable "batch_size" {
  description = "Maximum number of messages per invocation."
  type        = number
  default     = 10

  validation {
    condition     = var.batch_size >= 1 && var.batch_size <= 10
    error_message = "batch_size must be 1-10. Larger batches (up to 10000) also require a batching window and a function that handles them. This is not included in this module"
  }
}

variable "maximum_batching_window_seconds" {
  description = "How long to gather messages before invoking"
  type        = number
  default     = 0
}

variable "maximum_concurrency" {
  description = "Maximum number of Lambda runs this queue can start at once. Set to null to let AWS manage it."
  type        = number
  default     = null

  validation {
    condition     = var.maximum_concurrency == null ? true : (var.maximum_concurrency >= 2 && var.maximum_concurrency <= 1000)
    error_message = "maximum_concurrency must be between 2 and 1000 when set."
  }
}

variable "max_receive_count" {
  description = "Number of receives before a message is moved to the dead-letter queue."
  type        = number
  default     = 5
}

variable "message_retention_seconds" {
  description = "Retention on the main queue."
  type        = number
  default     = 345600 # 4 days
}

variable "dlq_message_retention_seconds" {
  description = "Retention on the dead-letter queue."
  type        = number
  default     = 1209600 # 14 days
}

variable "kms_key_arn" {
  description = "Optional customer-managed KMS key ARN used to encrypt both queues. When null, SQS-managed encryption (SSE-SQS) is used."
  type        = string
  default     = null
}

# Logging and monitoring

variable "log_retention_days" {
  description = "CloudWatch log retention for the function's log group."
  type        = number
  default     = 30
}

variable "create_alarms" {
  description = "Whether to create the CloudWatch alarms."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "ARNs (SNS topics, Lambda functions, CW Investigations) to notify when an alarm fires and when it returns to OK. Alerting target is not created by this module"
  type        = list(string)
  default     = []
}

variable "queue_age_alarm_threshold_seconds" {
  description = "Alarm when the oldest message on the main queue exceeds this age, this is a signal for when a lambda is falling behind on processing"
  type        = number
  default     = 600
}

variable "tags" {
  description = "Tags applied to all resources. Consider also setting provider default_tags in the calling configuration."
  type        = map(string)
  default     = {}
}
