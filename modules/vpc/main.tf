########################################
# INPUT VARIABLES
########################################

variable "account_id" {
  type = string
}


variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs (one per AZ)"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Common tags for all VPC resources"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

########################################
# LOCALS
########################################

locals {
  common_tags = var.tags
}

########################################
# VPC
########################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

########################################
# INTERNET GATEWAY
########################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw"
  })
}

########################################
# PUBLIC SUBNETS
########################################

resource "aws_subnet" "public" {
  for_each = zipmap(var.azs, var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${var.environment}-public-${each.key}"
    Network                  = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

########################################
# PUBLIC ROUTE TABLE
########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_associations" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

########################################
# NAT GATEWAY
########################################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id

  depends_on = [aws_internet_gateway.this]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-gw"
  })
}

########################################
# PRIVATE SUBNETS
########################################

resource "aws_subnet" "private" {
  for_each = zipmap(var.azs, var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.common_tags, {
    Name                              = "${var.environment}-private-${each.key}"
    Network                           = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

########################################
# PRIVATE ROUTE TABLE
########################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-rt"
  })
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_associations" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

########################################
# CloudWatch Log Group for Flow Logs
########################################

resource "aws_s3_bucket" "flow_logs" {
  bucket = "${var.environment}-vpc-flow-logs-${var.account_id}"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc-flow-logs-${var.account_id}"
  })
}


########################################
# VPC Flow Logs
########################################

resource "aws_flow_log" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id       = aws_vpc.this.id
  traffic_type = "ALL"

  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs.arn

  tags = local.common_tags
}


########################################
# OUTPUTS
########################################

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}


