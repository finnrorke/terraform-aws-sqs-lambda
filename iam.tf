# Scoped more precise permissions rather than AWSLambdaBasicExecutionRole
# Things like accessing the modules SQS queue and writing to the lambdas log group are all that is required by default
# User can supply their own permissions as they need.

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "runtime" {
  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  statement {
    sid = "ConsumeQueue"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.main.arn]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid       = "DecryptQueueMessages"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "runtime" {
  name   = "runtime"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.runtime.json
}

# Add policy arns for policies granting permissions to AWS resources the lambda has to access

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.lambda_policy_arns)

  role       = aws_iam_role.lambda.name
  policy_arn = each.value
}

# Add Lambda VPC access execution role when subnets are provided
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = var.vpc_subnet_ids != null ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
