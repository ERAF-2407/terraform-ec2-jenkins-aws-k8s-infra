variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Should be overridden with a specific IP
}

variable "allowed_jenkins_cidr" {
  description = "CIDR block allowed to access Jenkins UI"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Should be overridden with a specific IP
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium" # Changed from t3.micro to better handle Jenkins + ZAP + Docker
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "devsecops-jenkins"
}
