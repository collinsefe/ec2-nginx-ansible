# ============================================================================
# VARIABLES: Configurable inputs to the Terraform configuration
# ============================================================================
# Variables let you customize deployments without editing code.
# They can be provided via:
#  - Command line: -var="region=eu-west-1"
#  - Environment: TF_VAR_region=eu-west-1
#  - .tfvars files: terraform.tfvars (not in git!)
#  - Or use the defaults shown here

variable "region" {
  description = "AWS region where the instance will be deployed"
  type        = string
  default     = "eu-west-2" # London region
  # Regions: eu-west-1 (Ireland), us-east-1 (Virginia), ap-southeast-1 (Singapore)
}

variable "name" {
  description = "Name prefix for all resources (used in tags and resource names)"
  type        = string
  default     = "nginx-demo"
  # This becomes: nginx-demo-sg, nginx-demo-key, etc.
}

variable "instance_type" {
  description = "EC2 instance type (computing power + memory)"
  type        = string
  default     = "t3.micro" # Free tier eligible (1 vCPU, 1 GB RAM)
  # Other options: t3.small (1 vCPU, 2 GB), t3.medium (2 vCPU, 4 GB), etc.
  # See: https://aws.amazon.com/ec2/instance-types/t3/
}

variable "vpc_id" {
  description = "VPC ID to deploy into. Leave empty to use the default VPC"
  type        = string
  default     = ""
  # VPC = Virtual Private Cloud (your private network in AWS)
  # Default VPC = AWS automatically created one for your account
  # For production, create custom VPCs with specific CIDR ranges
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH in (your public IP as x.x.x.x/32)"
  type        = string
  # This is REQUIRED - you must provide it when running terraform apply
  # Example: "203.0.113.42/32" = only allow this one IP
  # /32 = single IP address (not a range)
  # Security: Never use "0.0.0.0/0" for SSH! That's the entire internet!
}

variable "public_key_path" {
  description = "Path to your SSH public key file (sent to AWS)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  # This file is READ by Terraform and uploaded to AWS
  # It's safe to upload public keys (the name says 'public'!)
  # The private key NEVER leaves your computer
}

variable "private_key_path" {
  description = "Path to your SSH private key file (used by Ansible to connect)"
  type        = string
  default     = "~/.ssh/id_ed25519"
  # Terraform writes this path to the Ansible inventory
  # Ansible uses this to connect to the EC2 instance
  # KEEP THIS SECRET! This file authenticates you to the instance!
}
