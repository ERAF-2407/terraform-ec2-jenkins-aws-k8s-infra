output "jenkins_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8081"
}

output "ssh_command" {
  description = "Command to SSH into the Jenkins server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.jenkins_server.public_ip}"
}
