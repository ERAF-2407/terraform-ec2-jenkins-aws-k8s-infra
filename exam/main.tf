# 1) Define variable in main.tf for your IP Address
variable "test_ip_address" {
  description = "Base IP address for SSH access (will be appended with /24)"
  type        = string
  default     = "0.0.0.0" # Placeholder, user should provide their IP
}

variable "key_name" {
  description = "Optional SSH key name"
  type        = string
  default     = ""
}

# 2) Region should be "us-west-2"
provider "aws" {
  region = "us-west-2"
}

# 3) VPC name should be "test_vpc" and CIDR block should be "10.0.0.0/16"
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test_vpc"
  }
}

# 4) Internet Gateway name should be "test_igw"
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test_igw"
  }
}

# 5) Subnet name should be "test_subnet" and CIDR block should be "10.0.1.0/22"
resource "aws_subnet" "test_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.0.0/22"
  map_public_ip_on_launch = true # Optimization: Ensure instances get a public IP

  tags = {
    Name = "test_subnet"
  }
}

# Extra: Route Table to allow internet access (implied by requirement)
resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "test_route_table"
  }
}

resource "aws_route_table_association" "test_rta" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.test_rt.id
}

# 6) Security group name should be "test_sg" and ingress details
resource "aws_security_group" "test_sg" {
  name        = "test_sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # CIDR Block = ${var.test_ip_address}/24
    cidr_blocks = ["${var.test_ip_address}/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test_sg"
  }
}

# Data source to find the latest Amazon Linux 2 AMI (Fix for malformed/invalid ID in requirement)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 7) EC2 instance name should be "test_instance"
resource "aws_instance" "test_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.test_subnet.id
  vpc_security_group_ids = [aws_security_group.test_sg.id]
  key_name               = var.key_name != "" ? var.key_name : null

  tags = {
    Name = "test_instance"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.test_instance.public_ip
}

output "ssh_connection_command" {
  description = "Command to connect to the instance via SSH"
  value       = "ssh ec2-user@${aws_instance.test_instance.public_ip}"
}
