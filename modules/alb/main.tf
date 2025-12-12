########################################
# ALB MODULE — ENTERPRISE VERSION
########################################

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for ALB"
}

variable "app_port" {
  type        = number
  default     = 80
  description = "Application port on EC2/targets"
}

variable "health_check_path" {
  type        = string
  default     = "/"
}

variable "enable_https" {
  type        = bool
  default     = false
  description = "Enable HTTPS listener using ACM certificate"
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN if HTTPS is enabled"
}

variable "enable_waf" {
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  type        = string
  default     = null
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
      Module      = "alb"
    }
  )
}

########################################
# Security Group
########################################

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alb-sg"
  })
}

########################################
# Load Balancer
########################################

resource "aws_lb" "this" {
  name               = "${var.environment}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  idle_timeout       = 60

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alb"
  })
}

########################################
# Target Group
########################################

resource "aws_lb_target_group" "this" {
  name     = "${var.environment}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-tg"
  })
}

########################################
# HTTP Listener (Redirect to HTTPS if enabled)
########################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"

      redirect {
        protocol   = "HTTPS"
        port       = "443"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }
}

########################################
# HTTPS Listener (Optional)
########################################

resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

########################################
# Optional WAF Web ACL
########################################

resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}

########################################
# Outputs
########################################

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}


