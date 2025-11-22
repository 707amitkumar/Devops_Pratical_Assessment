terraform {
  backend "s3" {
    bucket         = "devops-terraform-state-<yourname>"   # REPLACE
    key            = "global/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "devops-terraform-locks-<yourname>"    # REPLACE
    encrypt        = true
  }
}

