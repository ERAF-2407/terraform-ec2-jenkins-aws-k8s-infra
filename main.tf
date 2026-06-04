terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Security Groups ---
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Jenkins server with restricted access"
  vpc_id      = var.vpc_id

  ingress {
    description = "Jenkins UI"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = var.allowed_jenkins_cidr
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# --- AMI Data Source ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- IAM Role & Instance Profile ---
resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name    = "${var.project_name}-role"
    Project = var.project_name
  }
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.jenkins_role.name
}

# Scoped Policy for DevSecOps (EKS, ECR, EC2, IAM)
resource "aws_iam_role_policy" "jenkins_policy" {
  name = "${var.project_name}-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "eks:*",
          "ecr:*",
          "iam:*",
          "s3:*",
          "autoscaling:*",
          "cloudwatch:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Deny"
        Action   = ["organizations:*", "account:*"]
        Resource = "*"
      }
    ]
  })
}

# --- EC2 Instance ---
resource "aws_instance" "jenkins_server" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  
  user_data = file("${path.module}/install_jenkins.sh")

  root_block_device {
    volume_size = 30 # Increased for Docker images and ZAP
    volume_type = "gp3"
  }

  tags = {
    Name    = "Jenkins-Server"
    Project = var.project_name
  }

  lifecycle {
    ignore_changes = [ami] # Prevent unintentional replacement on AMI updates
  }
}

