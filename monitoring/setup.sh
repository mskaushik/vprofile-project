#!/bin/bash

# Install necessary packages
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Create monitoring directory
mkdir -p ~/vprofile-monitoring
cd ~/vprofile-monitoring

# Copy configuration files
cp -r monitoring/* .

# Set up AWS credentials
echo "Enter your AWS Access Key ID:"
read AWS_ACCESS_KEY_ID
echo "Enter your AWS Secret Access Key:"
read AWS_SECRET_ACCESS_KEY
echo "Enter your AWS Region (e.g., us-east-1):"
read AWS_REGION

# Create .env file
cat << EOF > .env
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_REGION=${AWS_REGION}
EOF

# Start monitoring stack
sudo docker-compose up -d

echo "Monitoring stack is now running!"
echo "Access Grafana at http://localhost:3000"
echo "Default credentials: admin/admin"
