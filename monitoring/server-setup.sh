#!/bin/bash

# Create directory with proper permissions
sudo mkdir -p /opt/monitoring
sudo chown ubuntu:ubuntu /opt/monitoring

# Clone the repository
cd /opt/monitoring
git clone -b monitoring-setup https://github.com/mskaushik/vprofile-project.git

# Move to the monitoring directory
cd vprofile-project/monitoring

# Run docker setup script
chmod +x docker-setup.sh
sudo ./docker-setup.sh

echo "Docker installation complete. Please log out and log back in, then run:"
echo "cd /opt/monitoring/vprofile-project/monitoring"
echo "docker-compose up -d"
