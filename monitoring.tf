# The application logs lines like:
#   2026-05-12 11:47:34,377 : ERROR : Error with AWS SQS request
# Metric filter on the ERROR keyword.
# CloudWatch alarms watch metrics, not logs. This filter turns each log event
# containing ERROR into a custom metric datapoint that the alarm below watches.

resource "aws_cloudwatch_log_metric_filter" "log_errors" {
  name           = "${var.name}-log-errors"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "ERROR"

  metric_transformation {
    name          = "${var.name}-log-errors"
    namespace     = "SqsLambda"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_errors" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-log-errors"
  alarm_description   = "Application logged one or more ERROR lines in the last minute."
  namespace           = "SqsLambda"
  metric_name         = "${var.name}-log-errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-lambda-errors"
  alarm_description   = "One or more invocations of ${var.name} failed in the last minute."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}

# Alarm for when messages have landed in DLQ
resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-dlq-not-empty"
  alarm_description   = "Messages have landed on the DLQ after ${var.max_receive_count} receives."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}

# Old messages exist in queue, user should investigtate, perhaps lambda functions are hanging,
# When lambda functions hang they can prevent new functions from running, causing messages to never
# be consumed.
resource "aws_cloudwatch_metric_alarm" "queue_backlog" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-queue-backlog"
  alarm_description   = "Oldest message on the queue is older than ${var.queue_age_alarm_threshold_seconds}s"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.queue_age_alarm_threshold_seconds
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}
