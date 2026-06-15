# DLQ to send failures to
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds

  # Explicit sse enabled if not using user supplied kms
  sqs_managed_sse_enabled = var.kms_key_arn == null ? true : null
  kms_master_key_id       = var.kms_key_arn

  tags = var.tags
}

resource "aws_sqs_queue" "main" {
  name = var.name

  # AWS recommends a visibility timeout of 6* the lambda function timeout to prevent a message
  # being redelivered while it's already in flight
  visibility_timeout_seconds = var.lambda_timeout * 6
  message_retention_seconds  = var.message_retention_seconds

  # Explicit sse enabled if not using user supplied kms
  sqs_managed_sse_enabled = var.kms_key_arn == null ? true : null
  kms_master_key_id       = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = var.tags
}

# Only the main queue may redrive into this dlq.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.this.arn

  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_seconds

  # Assuming the container is setup to return batchItemFailures
  function_response_types = ["ReportBatchItemFailures"]

  dynamic "scaling_config" {
    for_each = var.maximum_concurrency != null ? [1] : []
    content {
      maximum_concurrency = var.maximum_concurrency
    }
  }
}
