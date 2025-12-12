########################################
# S3 MODULE — ENTERPRISE UPGRADED VERSION
########################################

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "bucket_name_prefix" {
  type        = string
  description = "Prefix for bucket name"
}

variable "enable_server_access_logging" {
  type        = bool
  default     = false
  description = "Enable S3 server access logging"
}

variable "log_bucket_name" {
  type        = string
  default     = null
  description = "Bucket to store access logs (required if logging enabled)"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

locals {
  bucket_name = "${var.bucket_name_prefix}-${var.environment}"
}

########################################
# Create Bucket
########################################

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  tags = merge(var.tags, {
    Name        = local.bucket_name
    Environment = var.environment
  })
}

########################################
# Block ALL Public Access
########################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.this]
}

########################################
# Versioning
########################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket.this]
}

########################################
# Encryption (AES256)
########################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }

  depends_on = [aws_s3_bucket.this]
}

########################################
# Enforce TLS (No HTTP access)
########################################

resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

########################################
# Lifecycle Rules (Noncurrent Cleanup)
########################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-noncurrent-after-30-days"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_versioning.this
  ]
}

########################################
# Optional Logging
########################################

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_server_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.log_bucket_name
  target_prefix = "${local.bucket_name}/logs/"

  depends_on = [aws_s3_bucket.this]
}

########################################
# OUTPUTS
########################################

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}


