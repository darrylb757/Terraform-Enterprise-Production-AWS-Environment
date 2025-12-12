########################################
# COMPUTE / ASG MODULE — ENTERPRISE VERSION
########################################

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for EC2 security group"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for instances"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID (for ingress into app tier)"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "min_size" {
  type        = number
  default     = 1
}

variable "max_size" {
  type        = number
  default     = 3
}

variable "desired_capacity" {
  type        = number
  default     = 1
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH (if needed)"
}

variable "ec2_instance_profile_name" {
  type        = string
  description = "IAM instance profile name for EC2"
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN"
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
      Module      = "compute-asg"
    }
  )
}

########################################
# Security Group for EC2 instances
########################################

resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "EC2 instances security group"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Allow all outbound (instances can reach Internet via NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-ec2-sg"
  })
}

########################################
# AMI Lookup (Amazon Linux 2)
########################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

########################################
# Launch Template
########################################

resource "aws_launch_template" "this" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    security_groups             = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = false
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum update -y
    amazon-linux-extras install -y nginx1
    systemctl enable nginx
    echo "Hello from ${var.environment}!" > /usr/share/nginx/html/index.html
    systemctl start nginx
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.environment}-ec2"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${var.environment}-ec2-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-launch-template"
  })
}

########################################
# Auto Scaling Group
########################################

resource "aws_autoscaling_group" "this" {
  name                      = "${var.environment}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Keep capacity healthy during Spot/On-Demand issues (future upgrade)
  capacity_rebalance = true

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# OUTPUTS
########################################

output "asg_name" {
  value       = aws_autoscaling_group.this.name
  description = "Name of the Auto Scaling group"
}

output "ec2_security_group_id" {
  value       = aws_security_group.ec2_sg.id
  description = "Security group ID used by EC2 instances"
}



