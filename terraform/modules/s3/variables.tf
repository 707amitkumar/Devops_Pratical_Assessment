variable "name" { type = string }
variable "region" { type = string }

variable "acl" {
  type    = string
  default = "private"
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "enable_sse" {
  type    = bool
  default = true
}

variable "kms_enabled" {
  type    = bool
  default = true
}

variable "kms_description" {
  type    = string
  default = ""
}

variable "lifecycle_rules" {
  type    = list(any)
  default = []
}

variable "logging_target_bucket" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

