output "vpc_id" {
  value       = data.aws_vpc.selected.id
  description = "VPC ID where the instance is deployed"
}

output "vpc_cidr" {
  value       = data.aws_vpc.selected.cidr_block
  description = "VPC CIDR block"
}

output "subnet_id" {
  value       = aws_instance.web.subnet_id
  description = "Subnet ID where the instance is deployed"
}

output "instance_id" {
  value       = aws_instance.web.id
  description = "EC2 instance ID"
}

output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP address of the instance"
}

output "private_ip" {
  value       = aws_instance.web.private_ip
  description = "Private IP address of the instance"
}

output "security_group_id" {
  value       = aws_security_group.web.id
  description = "Security group ID"
}

output "url" {
  value       = "http://${aws_instance.web.public_dns}"
  description = "URL to access nginx"
}
