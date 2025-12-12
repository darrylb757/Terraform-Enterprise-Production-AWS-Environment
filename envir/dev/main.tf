locals {
  common_tags = {
    Project     = "project1"
    Environment = var.environment
    Owner       = "Darryl Brown"
  }
}

########################################
# VPC
########################################

module "vpc" {
  source               = "../../modules/vpc"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  account_id           = var.account_id
  tags                 = local.common_tags
}


########################################
# S3
########################################

module "s3" {
  source = "../../modules/s3"

  environment        = var.environment
  bucket_name_prefix = "db-project1-app"


  tags = local.common_tags
}

########################################
# IAM
########################################

module "iam" {
  source = "../../modules/iam"

  environment = var.environment


  tags = local.common_tags
}

########################################
# ALB
########################################

module "alb" {
  source = "../../modules/alb"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  app_port = 80


  tags = local.common_tags
}

########################################
# Compute / ASG
########################################

module "compute_asg" {
  source = "../../modules/compute-asg"

  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  alb_security_group_id     = module.alb.alb_security_group_id
  key_name                  = var.key_name
  ec2_instance_profile_name = module.iam.ec2_instance_profile_name
  target_group_arn          = module.alb.target_group_arn


  tags = local.common_tags
}

########################################
# Monitoring
########################################

module "monitoring" {
  source = "../../modules/monitoring"

  environment           = var.environment
  asg_name              = module.compute_asg.asg_name
  sns_email             = var.sns_email
  slack_webhook_url     = var.slack_webhook_url
  monthly_budget_amount = var.monthly_budget_amount
  account_id            = var.account_id
  lambda_role_arn       = module.iam.lambda_role_arn


  tags = local.common_tags
}


