# Minimal example of consuming the module.
#
# Credentials and backend configuration deliberately live OUTSIDE the code:
#  - auth comes from the environment (SSO, instance profile, OIDC in CI)
#  - state backend is configured per environment (e.g. -backend-config or a
#    backend.tf owned by the consuming team)

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Service   = "event-notifications"
      ManagedBy = "terraform"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "image_uri" {
  description = "ECR image URI"
  type        = string
}

variable "alarm_topic_arn" {
  description = "Existing SNS topic for alarm notifications."
  type        = string
}


data "aws_iam_policy_document" "lambda_app_access" {
  statement {
    sid = "ReadDataBucket"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::fake-bucket/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_app_access" {
  name        = "event-notifications-lambda-app-access"
  description = "Application-specific permissions for the event notifications Lambda."
  policy      = data.aws_iam_policy_document.lambda_app_access.json
}

module "event_processor" {
  source = "../.."

  name      = "event-notifications"
  image_uri = var.image_uri

  lambda_timeout      = 30
  maximum_concurrency = 20

  lambda_policy_arns = [aws_iam_policy.lambda_app_access.arn]

  alarm_actions = [var.alarm_topic_arn]
}

output "queue_url" {
  value = module.event_processor.queue_url
}
