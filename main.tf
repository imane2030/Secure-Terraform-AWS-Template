terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Configure remote state backend
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "secure-infra/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   kms_key_id     = "arn:aws:kms:us-east-1:ACCOUNT:key/KEY-ID"
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Environment = "production"
      Compliance  = "NIST-800-53"
    }
  }
}

# Random ID for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}
