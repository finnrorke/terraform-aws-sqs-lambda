# Lambda Function
# This lambda function is running a container image rather than a packaged zip
# By default the lambda function runs outside a VPC, if the user wants to access
# private resources (like RDS, ElastiCache and other internal services) they can provide 
# private subnets and a NAT route

resource "aws_lambda_function" "this" {
  function_name = var.name
  description   = "Processes event notifications from SQS queue ${var.name}"

  package_type = "Image"
  image_uri    = var.image_uri

  role        = aws_iam_role.lambda.arn
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  reserved_concurrent_executions = var.reserved_concurrency
  
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # Create the log group first so Lambda doesn't automatically create an
  # unmanaged one with infinite retention
  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
