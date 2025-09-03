#!/bin/bash

echo "Cleaning up Docker system..."
docker system prune -af --volumes

echo "Cleaning up old logs..."
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete
sudo journalctl --vacuum-time=2d

echo "Cleaning up package manager cache..."
sudo apt-get clean
sudo apt-get autoremove -y

echo "Cleaning up temporary files..."
sudo rm -rf /tmp/*

echo "Current disk usage:"
df -h /

echo "Top 10 largest directories:"
du -ha / 2>/dev/null | sort -rh | head -n 10
