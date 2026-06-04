# DevSecOps AWS Infrastructure with Terraform & Jenkins

This project provides a secure, automated foundation for a DevSecOps pipeline on AWS. It uses Terraform to provision a Jenkins server equipped with essential security and deployment tools.

## DevSecOps Enhancements
- **IAM Least Privilege:** Scoped IAM roles for EC2, EKS, and ECR.
- **Network Hardening:** Restricted Security Groups via variables.
- **Security Tooling:** Automatic installation of `Trivy` (SCA/Container Scanning), `Docker`, `kubectl`, and `eksctl`.
- **Infrastructure as Code (IaC) Best Practices:** Variabilized configuration, improved state management preparation, and modular structure.
- **Automated Pipeline:** Included `Jenkinsfile.example` with SCA, Build, Scan, and DAST stages.

## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.0.0)
- AWS CLI configured with appropriate permissions.
- An existing VPC (or use the one in the `exam/` folder for testing).
- An EC2 Key Pair.

## Deployment Steps

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Configure Variables
Create a `terraform.tfvars` file or use the command line to provide values for:
- `vpc_id`
- `key_name`
- `allowed_ssh_cidr` (e.g., `["203.0.113.1/32"]`)
- `allowed_jenkins_cidr` (e.g., `["203.0.113.1/32"]`)

### 3. Plan and Apply
```bash
terraform plan
terraform apply
```

### 4. Access Jenkins
Once the instance is ready (it may take 5-10 minutes for `user_data` to finish):
1. Get the Jenkins URL from the Terraform output.
2. SSH into the instance using the `ssh_command` output.
3. Get the initial admin password:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

## Included Tools
- **Jenkins:** CI/CD Orchestrator (Port 8081).
- **Trivy:** Security scanner for vulnerabilities in container images, file systems, and Git repositories.
- **Docker:** Container runtime for building and running images.
- **Kubectl & Eksctl:** Tools for managing Kubernetes clusters and EKS.
- **AWS CLI v2:** For AWS resource management.

## Cleanup
```bash
terraform destroy
```
