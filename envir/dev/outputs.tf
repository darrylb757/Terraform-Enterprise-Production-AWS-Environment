output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "app_bucket_name" {
  value = module.s3.bucket_name
}

output "asg_name" {
  value = module.compute_asg.asg_name
}

output "alerts_topic_arn" {
  value = module.monitoring.alerts_topic_arn
}


