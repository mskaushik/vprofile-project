#!/bin/bash

# Update package list
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
sudo apt install -y docker.io

# Install Docker Compose
sudo apt install -y docker-compose

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Verify installations
docker --version
docker-compose --version

# Test Docker
sudo docker run hello-world

echo "Please log out and log back in for the group changes to take effect."
