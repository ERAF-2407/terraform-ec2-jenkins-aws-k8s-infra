#!/bin/bash

# --- Optimización para Instancias Pequeñas (t2.micro) ---
# Crear un archivo Swap de 2GB para evitar errores de memoria (OOM)
sudo dd if=/dev/zero of=/swapfile bs=128M count=16
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# Actualizar paquetes
sudo yum update -y

# Instalar Java 17 (Requerido por Jenkins)
sudo dnf install java-17-amazon-corretto-devel -y
sudo update-alternatives --set java /usr/lib/jvm/java-17-amazon-corretto.x86_64/bin/java

# Configurar repositorio de Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y

# Instalar herramientas básicas
sudo yum install git wget unzip jq nodejs npm -y

# Instalar Maven
sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
sudo yum install -y apache-maven

# Instalar Jenkins
sudo yum install jenkins -y
# Cambiar puerto de Jenkins a 8081 (opcional, según tu configuración original)
sudo sed -i -e 's/Environment="JENKINS_PORT=[0-9]\+"/Environment="JENKINS_PORT=8081"/' /usr/lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Instalar ZAP (Zed Attack Proxy)
sudo wget https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2_14_0_unix.sh
sudo chmod +x ZAP_2_14_0_unix.sh
sudo ./ZAP_2_14_0_unix.sh -q -dir /opt/zaproxy
rm ZAP_2_14_0_unix.sh

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Instalar eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Instalar Docker y configurar permisos
sudo yum install docker -y
sudo systemctl enable docker
sudo systemctl start docker
# Agregar usuarios al grupo docker (sin usar newgrp para evitar bloqueos en script)
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

# Reiniciar Jenkins para aplicar permisos de Docker
sudo systemctl restart jenkins
