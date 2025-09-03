#!/bin/bash

# Stop existing containers
docker-compose down

# Remove existing volumes
docker volume rm monitoring_prometheus_data monitoring_grafana_data || true

# Create directories with proper permissions
sudo mkdir -p data/prometheus data/grafana
sudo chown -R 65534:65534 data/prometheus  # nobody:nogroup for Prometheus
sudo chown -R 472:472 data/grafana  # grafana:grafana for Grafana

# Start the stack
docker-compose up -d

# Check logs
echo "Prometheus logs:"
docker-compose logs prometheus
