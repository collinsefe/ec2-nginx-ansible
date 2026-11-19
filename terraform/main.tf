# ============================================================================
# TERRAFORM CONFIGURATION: nginx on EC2
# ============================================================================
# This Terraform configuration demonstrates:
# - Defining provider requirements and versions
# - Creating EC2 instances, security groups, and key pairs
# - Using data sources to reference existing resources
# - Generating configuration files dynamically
# - AWS security best practices (IMDSv2, encryption, etc.)
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.region # Connect to AWS in the specified region
}

# ============================================================================
# DATA SOURCES: Look up existing AWS resources
# ============================================================================
# Data sources don't create resources; they query AWS to find existing ones.
# This is powerful for reusing existing infrastructure.

# Latest Ubuntu 24.04 LTS AMI from Canonical
# AMI = Amazon Machine Image (a pre-built Linux/Windows image)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account (official Ubuntu images)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # HVM = Hardware Virtual Machine (modern, faster)
  }
  # This finds the newest Ubuntu 24.04 image, ensuring we always get the latest patches
}

# Look up the VPC (Virtual Private Cloud) where the instance will be deployed
data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null # Use default VPC if none specified
  # VPC = your private network in AWS where instances can communicate securely
}

# Look up public subnets in the selected VPC
# A subnet = a subdivision of the VPC with its own IP range
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"] # Only public subnets (accessible from internet)
  }
}

# ============================================================================
# RESOURCES: Create new AWS infrastructure
# ============================================================================

# Create an EC2 Key Pair for SSH access
# This uploads your public key to AWS so instances can recognize your computer
resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"         # Name to identify this key in AWS
  public_key = file(var.public_key_path) # Read your public key from ~/.ssh/id_ed25519.pub
  # Key pairs = how you authenticate to EC2 instances over SSH (no passwords!)
}

# Create a Security Group (virtual firewall)
# Controls which network traffic can reach the EC2 instance
resource "aws_security_group" "web" {
  name        = "${var.name}-sg"
  description = "SSH from admin IP, HTTP from anywhere, internal VPC traffic"
  vpc_id      = data.aws_vpc.selected.id

  # INGRESS = incoming traffic (into the instance)

  # Allow SSH (port 22) only from your IP
  # This prevents the entire internet from trying to log in
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr] # Your public IP, determined at deploy time
  }

  # Allow HTTP (port 80) from anywhere
  # Anyone on the internet can visit the nginx website
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 = entire internet
  }

  # Allow internal VPC communication
  # If you have multiple EC2 instances, they can talk to each other
  ingress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # EGRESS = outgoing traffic (from the instance)

  # Allow all outgoing traffic
  # The instance can reach the internet (for apt updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-sg" }
}

# Create an EC2 Instance (virtual machine)
# This is the core of the infrastructure: a Linux server in the cloud
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id           # Use the latest Ubuntu image we found
  instance_type               = var.instance_type                # t3.micro = small, free-tier eligible
  key_name                    = aws_key_pair.this.key_name       # Use the key pair we created
  vpc_security_group_ids      = [aws_security_group.web.id]      # Apply the security group
  subnet_id                   = data.aws_subnets.selected.ids[0] # Deploy in first public subnet
  associate_public_ip_address = true                             # Give it a public IP (accessible from internet)

  # Security: Use IMDSv2 (Instance Metadata Service v2)
  # Prevents misconfigured apps from leaking credentials
  metadata_options {
    http_tokens = "required" # Require a token to access instance metadata
  }

  # Storage configuration
  root_block_device {
    volume_size = 8     # 8 GB is plenty for nginx
    volume_type = "gp3" # General Purpose SSD (fast and affordable)
    encrypted   = true  # Encrypt the disk (security best practice)
  }

  tags = { Name = var.name }
}

# Generate Ansible Inventory File
# This file tells Ansible which servers to configure and how to reach them
# Terraform writes this AFTER the EC2 instance is created
resource "local_file" "inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [web]
    ${aws_instance.web.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}
  EOT
  # This creates a file like:
  #   [web]
  #   52.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
  #
  # Key components:
  #   [web] = Ansible group name (matches our playbook's "hosts: web")
  #   52.123.45.67 = The instance's public IP address
  #   ansible_user = Which user to log in as (ubuntu is the default on Ubuntu images)
  #   ansible_ssh_private_key_file = Where to find the private key for authentication
}
