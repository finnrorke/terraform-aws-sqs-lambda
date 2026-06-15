# terraform-aws-sqs-lambda

Terraform module for an SQS queue that invokes a Lambda function packaged as an ECR container image.

## Creates

- SQS queue
- SQS dead-letter queue
- Lambda function using `package_type = "Image"`
- Lambda execution role and runtime policy
- CloudWatch log group
- CloudWatch alarms for Lambda errors, log errors, DLQ messages, and old queue messages
- Lambda event source mapping from SQS to Lambda

## Assumptions

- Terraform is `>= 1.5`.
- AWS provider is `>= 5.0, < 7.0`.
- The Lambda image already exists in ECR.
- `image_uri` is pinned to an immutable image digest or tag.
- AWS credentials, state backend, and provider configuration are owned by the terraform project consuing the module.
- Environment variables are plain text. No encryption, use secrets or ssm for private information and keys
- By default, the Lambda function is not attached to a VPC and has outbound internet access through the Lambda service.
- If `vpc_subnet_ids` is set, the supplied subnets and security groups must allow the function to reach the required VPC-private resources. If the function also needs internet egress, the selected subnets need a NAT gateway or equivalent.
- The event source mapping enables `ReportBatchItemFailures`. The function should return the failures ("batchItemFailures": {"itemIdentifier": sqs_record})
- The queue visibility timeout is always `lambda_timeout * 6`.
- The dead-letter queue accepts redrive only from the main queue created by this module.
- If `kms_key_arn` is not set, both queues use SQS-managed server-side encryption.
- Alarm delivery is handled by whatever ARNs are passed in `alarm_actions`, usually SNS topics.

## Usage

```hcl
module "event_processor" {
  source = "git::https://github.com/finnrorke/terraform-aws-sqs-lambda.git"

  name      = "event-notifications"
  image_uri = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/event-processor@sha256:abc..."

  lambda_timeout      = 30
  maximum_concurrency = 20

  lambda_policy_arns = [aws_iam_policy.lambda_app_access.arn]
  alarm_actions      = [aws_sns_topic.oncall.arn]

  tags = {
    Service = "event-notifications"
  }
}
```

See [examples/basic/main.tf](examples/basic/main.tf) for a fuller example.

## Required Inputs

| Name | Description |
| --- | --- |
| `name` | Base name for created resources. |
| `image_uri` | Full ECR image URI, including tag or digest. |

## Optional Inputs

| Name | Default |
| --- | --- |
| `lambda_timeout` | `30` |
| `lambda_memory_size` | `512` |
| `environment_variables` | `{}` |
| `lambda_policy_arns` | `[]` |
| `reserved_concurrency` | `-1` |
| `vpc_subnet_ids` | `null` |
| `vpc_security_group_ids` | `[]` |
| `batch_size` | `10` |
| `maximum_batching_window_seconds` | `0` |
| `maximum_concurrency` | `null` |
| `max_receive_count` | `5` |
| `message_retention_seconds` | `345600` |
| `dlq_message_retention_seconds` | `1209600` |
| `kms_key_arn` | `null` |
| `log_retention_days` | `30` |
| `create_alarms` | `true` |
| `alarm_actions` | `[]` |
| `queue_age_alarm_threshold_seconds` | `600` |
| `tags` | `{}` |

## Outputs

- `queue_url`
- `queue_arn`
- `dlq_url`
- `dlq_arn`
- `function_name`
- `function_arn`
- `execution_role_arn`
- `execution_role_name`
- `log_group_name`

## Alarms

| Alarm | Signal |
| --- | --- |
| `${name}-lambda-errors` | Lambda invocation errors. |
| `${name}-log-errors` | CloudWatch log events matching `ERROR`. |
| `${name}-dlq-not-empty` | Messages visible on the DLQ. |
| `${name}-queue-backlog` | Oldest visible main queue message exceeds `queue_age_alarm_threshold_seconds`. |
