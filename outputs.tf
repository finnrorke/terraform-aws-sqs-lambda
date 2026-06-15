output "queue_url" {
  description = "URL of the main queue — producers send messages here."
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN of the main queue, e.g. for granting producers sqs:SendMessage."
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "execution_role_arn" {
  description = "ARN of the function's execution role, for attaching additional application permissions."
  value       = aws_iam_role.lambda.arn
}

output "execution_role_name" {
  description = "Name of the function's execution role."
  value       = aws_iam_role.lambda.name
}

output "log_group_name" {
  description = "CloudWatch log group the function writes to."
  value       = aws_cloudwatch_log_group.lambda.name
}
