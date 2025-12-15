output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = aws_cloudtrail.main.name
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.cloudtrail.id
}

output "app_role_arn" {
  description = "IAM role ARN for application instances"
  value       = aws_iam_role.app_role.arn
}

output "bastion_sg_id" {
  description = "Security group ID for bastion host"
  value       = aws_security_group.bastion_sg.id
}

output "app_sg_id" {
  description = "Security group ID for application tier"
  value       = aws_security_group.app_sg.id
}
