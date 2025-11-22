provider "aws" {
  region = var.region
}

# -----------------------------
# KMS KEY
# -----------------------------
resource "aws_kms_key" "this" {
  count                   = var.kms_enabled ? 1 : 0
  description             = var.kms_description
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.name}-kms"
  })
}

# -----------------------------
# S3 BUCKET
# -----------------------------
resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name = var.name
  })
}

# Block public access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_sse ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_enabled ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_enabled ? aws_kms_key.this[0].arn : null
    }
  }
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id      = rule.value.id
      status  = rule.value.enabled ? "Enabled" : "Disabled"
      prefix  = rule.value.prefix

      expiration {
        days = lookup(rule.value.expiration, "days", null)
      }

      noncurrent_version_expiration {
        days = lookup(rule.value.noncurrent_version_expiration, "days", null)
      }

      abort_incomplete_multipart_upload {
        days_after_initiation = rule.value.abort_incomplete_mpu_days
      }
    }
  }
}

# Logging
resource "aws_s3_bucket_logging" "this" {
  count = var.logging_target_bucket != "" ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging_target_bucket
  target_prefix = "${var.name}/logs/"
}

# Deny insecure access
data "aws_iam_policy_document" "deny_insecure" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.deny_insecure.json
}

