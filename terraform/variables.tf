variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2" # London
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "nginx-demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID to deploy into (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH in, e.g. your public IP as x.x.x.x/32"
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key uploaded as the EC2 key pair"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "private_key_path" {
  description = "Path to the matching private key (used in the Ansible inventory)"
  type        = string
  default     = "~/.ssh/id_ed25519"
}
