#!/bin/bash

echo "Installing Docker"
sudo apt install docker.io -y
sudo systemctl enable --now docker

echo "Adding Jenkins to Docker group"
sudo usermod -aG docker jenkins

echo "Downloading SonarQube Image"
sudo docker pull sonarqube:community

echo "Running SonarQube Container"
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:community

echo "Installation Completed"