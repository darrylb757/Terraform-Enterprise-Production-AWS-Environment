########################################
# IAM MODULE — ENTERPRISE VERSION
########################################

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Module      = "iam"
    }
  )
}

########################################
# EC2 ROLE + INSTANCE PROFILE
########################################

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.environment}-ec2-role"
  })
}

# Baseline EC2 permissions:
# - SSM (connect to the instance via SSM Session Manager)
# - CloudWatch logs
# - Basic EC2 read-only permissions
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

########################################
# LAMBDA ROLE (Monitoring Notifications)
########################################

resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.environment}-lambda-role"
  })
}

# Required for CloudWatch logs + SNS Invoke
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_monitoring_custom" {
  name = "${var.environment}-lambda-monitoring-inline"

  role = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = "*"
      }
    ]
  })
}

########################################
# FUTURE EXPANSION (Optional Roles)
########################################
# These are commented templates you can enable later:
#
# - ECS task execution role
# - EKS worker node role
# - CloudWatch agent role
# - S3 read/write role
#
# This keeps your module scalable for future projects.

########################################
# OUTPUTS
########################################

output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "Instance profile for EC2"
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "IAM role ARN for Lambda monitoring function"
}
