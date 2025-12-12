########################################
# MONITORING MODULE — ENTERPRISE UPGRADE
########################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

variable "environment"         { type = string }
variable "asg_name"            { type = string }
variable "sns_email"           { type = string }
variable "slack_webhook_url"   { type = string }
variable "monthly_budget_amount" { type = number }
variable "account_id"          { type = string }
variable "lambda_role_arn"     { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Module      = "monitoring"
    }
  )
}

########################################
# SNS ALERT TOPIC
########################################

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts-topic"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alerts-topic"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

########################################
# LAMBDA PACKAGING (Slack Notifier)
########################################

data "archive_file" "slack_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/slack_lambda.py"
  output_path = "${path.module}/lambda/slack_lambda.zip"
}

resource "aws_lambda_function" "slack_notifier" {
  function_name = "${var.environment}-slack-notifier"
  runtime       = "python3.11"
  handler       = "slack_lambda.lambda_handler"
  role          = var.lambda_role_arn

  filename         = data.archive_file.slack_zip.output_path
  source_code_hash = data.archive_file.slack_zip.output_base64sha256

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-slack-notifier"
  })
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

########################################
# CLOUDWATCH ALARMS
########################################

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 75
  period              = 60
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 10
  period              = 60
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

########################################
# AWS BUDGET (v6.x Compatible)
########################################

resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "LinkedAccount"
    values = [var.account_id]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold_type             = "PERCENTAGE"
    threshold                  = 80

    subscriber_email_addresses = [var.sns_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.alerts.arn]
  }
}

########################################
# OUTPUTS
########################################

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}


