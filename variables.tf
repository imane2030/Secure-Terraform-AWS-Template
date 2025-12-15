variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
  default     = "secure-aws"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT Gateway for private subnets"
  default     = true
}

variable "enable_vpn_gateway" {
  type        = bool
  description = "Enable VPN Gateway"
  default     = false
}

variable "cloudtrail_retention_days" {
  type        = number
  description = "CloudTrail log retention in days"
  default     = 90

  validation {
    condition     = var.cloudtrail_retention_days >= 90
    error_message = "CloudTrail retention must be at least 90 days for compliance."
  }
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR block allowed to SSH to bastion (change from 0.0.0.0/0)"
  default     = "0.0.0.0/0"
}
