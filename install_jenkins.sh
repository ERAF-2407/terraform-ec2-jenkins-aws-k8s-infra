#!/bin/bash
set -e # Exit on error

# --- DevSecOps Jenkins Installation Script ---
# Optimized for Amazon Linux 2023

echo "Starting Jenkins installation and configuration..."

# 1. Swap Space (Prevention of OOM on smaller instances)
if [ ! -f /swapfile ]; then
    sudo dd if=/dev/zero of=/swapfile bs=128M count=16
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
fi

# 2. System Updates
sudo dnf update -y

# 3. Dependencies (Java 17, Fonts, Git, jq, etc.)
sudo dnf install -y java-17-amazon-corretto fontconfig dejavu-sans-fonts git wget unzip jq nodejs npm

# 4. Jenkins Repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf upgrade -y

# 5. Jenkins Installation & Deep Configuration
sudo dnf install -y jenkins

# Asegurar permisos en directorios críticos
sudo chown -R jenkins:jenkins /var/lib/jenkins /var/cache/jenkins /var/log/jenkins

# Override de Systemd con optimizaciones de memoria agresivas para t3.micro
sudo mkdir -p /etc/systemd/system/jenkins.service.d
cat <<EOF | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JENKINS_PORT=8081"
# JAVA_OPTS optimizado: 
# -Xmx512m (Máximo), -Xms256m (Inicio), -XX:+UseSerialGC (Ahorra CPU/RAM en 1 sola vCPU)
Environment="JAVA_OPTS=-Xmx512m -Xms256m -Djava.awt.headless=true -XX:+UseSerialGC"
EOF

sudo systemctl daemon-reload
sudo systemctl enable jenkins
# Intentar arrancar Jenkins. Si falla, mostrar el error en el log de cloud-init
sudo systemctl start jenkins || (sudo journalctl -u jenkins --no-pager | tail -n 50)

# 6. AWS CLI v2
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
fi

# 7. Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

# 8. Kubernetes Tools (kubectl, eksctl)
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# 9. DevSecOps Tools (Trivy)
TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | jq -r .tag_name | sed 's/v//')
wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.rpm
sudo dnf install -y ./trivy_${TRIVY_VERSION}_Linux-64bit.rpm
rm trivy_${TRIVY_VERSION}_Linux-64bit.rpm

# 10. Final Restart to apply all group permissions
sudo systemctl restart jenkins

echo "Installation complete!"
