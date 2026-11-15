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
  region = var.region
}

# Latest Ubuntu 24.04 LTS AMI from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_key_pair" "this" {
  count      = try(file(pathexpand(var.public_key_path)), null) != null ? 1 : 0
  key_name   = "${var.name}-key"
  public_key = try(file(pathexpand(var.public_key_path)), "")

  lifecycle {
    ignore_changes = []
  }
}

resource "aws_security_group" "web" {
  name        = "${var.name}-sg"
  description = "SSH from admin IP, HTTP from anywhere, internal VPC traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-sg" }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = try(aws_key_pair.this[0].key_name, null)
  vpc_security_group_ids      = [aws_security_group.web.id]
  subnet_id                   = data.aws_subnets.selected.ids[0]
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = var.name }
}

# Write an Ansible inventory pointing at the new instance
resource "local_file" "inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [web]
    ${aws_instance.web.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}
  EOT
}
