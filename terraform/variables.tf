variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "tfstate_bucket" {
  description = "S3 bucket for Terraform backend state"
  type        = string
  default     = ""
}

variable "tfstate_prefix" {
  description = "Path prefix for backend state file"
  type        = string
  default     = "terraform"
}

variable "tf_workspace" {
  description = "Terraform workspace name"
  type        = string
  default     = "default"
}

