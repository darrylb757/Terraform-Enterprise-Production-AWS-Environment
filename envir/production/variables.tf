variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

########################################
# Networking
########################################

variable "vpc_cidr" {
  description = "VPC CIDR for this env"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets"
  type        = list(string)
  default     = ["10.2.11.0/24", "10.2.12.0/24"]
}

variable "azs" {
  description = "AZs to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

########################################
# Compute / ASG
########################################

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

########################################
# ALB
########################################

variable "alb_health_check_path" {
  type    = string
  default = "/"
}

########################################
# S3
########################################

variable "bucket_name_prefix" {
  type        = string
  default     = "db-project1-app"
  description = "Prefix for app bucket"
}

########################################
# Monitoring
########################################

variable "sns_email" {
  description = "Email for alerts"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook for alerts"
  type        = string
}

variable "monthly_budget_amount" {
  description = "Monthly budget for this env"
  type        = number
  default     = 100
}

########################################
# Common Tags
########################################

variable "tags" {
  description = "Base tags"
  type        = map(string)
  default = {
    Project = "project1"
  }
}
variable "project" {
  description = "Project name for tagging"
  type        = string
}

