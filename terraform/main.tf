# Generate random suffix for S3 bucket to avoid collisions
resource "random_id" "bucket" {
  byte_length = 4
}

# -----------------------------
# VPC MODULE
# -----------------------------
module "vpc" {
  source = "./modules/vpc"

  name  = "devops-vpc-${var.env}"
  cidr  = "10.0.0.0/16"
  azs   = ["${var.region}a", "${var.region}b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  tags = {
    Environment = var.env
    Project     = "devops-interview"
  }
}

# -----------------------------
# S3 MODULE
# -----------------------------
module "s3" {
  source = "./modules/s3"

  name   = "devops-s3-${var.env}-${random_id.bucket.hex}"
  region = var.region

  acl                  = "private"
  force_destroy        = false
  enable_versioning    = true
  enable_sse           = true
  kms_enabled          = true
  kms_description      = "KMS key for S3 bucket encryption"

  lifecycle_rules = [
    {
      id        = "logs-expire"
      enabled   = true
      prefix    = "logs/"
      expiration = { days = 365 }
      noncurrent_version_expiration = { days = 90 }
      abort_incomplete_mpu_days = 7
    }
  ]

  logging_target_bucket = ""  # set if you have a logging bucket

  tags = {
    Environment = var.env
    Project     = "devops-interview"
  }
}

# -----------------------------
# OUTPUTS
# -----------------------------
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "kms_key_arn" {
  value = module.s3.kms_key_arn
}

