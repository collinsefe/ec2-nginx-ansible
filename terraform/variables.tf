# ============================================================================
# VARIABLES: Configurable inputs to the Terraform configuration
# ============================================================================

variable "region" {
  description = "AWS region where the instance will be deployed"
  type        = string
  default     = "eu-west-2" 
  }

variable "name" {
  description = "Name prefix for all resources (used in tags and resource names)"
  type        = string
  default     = "nginx-demo-ansible-server"
}

variable "instance_type" {
  description = "EC2 instance type (computing power + memory)"
  type        = string
  default     = "t3.micro" 
}

variable "vpc_id" {
  description = "VPC ID to deploy into. Leave empty to use the default VPC"
  type        = string
  default     = ""
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH in (your public IP as x.x.x.x/32)"
  type        = string

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
