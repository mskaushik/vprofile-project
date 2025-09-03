#!/bin/bash

echo "Stopping existing containers..."
docker-compose down

echo "Cleaning up existing volumes..."
docker volume rm monitoring_prometheus_data monitoring_grafana_data || true

echo "Creating directories with proper permissions..."
sudo mkdir -p data/prometheus data/grafana
sudo chown -R 65534:65534 data/prometheus
sudo chown -R 472:472 data/grafana
sudo chmod -R 777 data/prometheus data/grafana

echo "Pulling latest images..."
docker-compose pull

echo "Starting the stack..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

echo "Checking container status..."
docker-compose ps

echo "Checking Prometheus logs..."
docker-compose logs prometheus

echo "Testing Prometheus endpoint..."
curl -v http://localhost:9090

echo "Checking network..."
docker network ls
docker network inspect monitoring_monitoring

echo "Container IP addresses:"
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker-compose ps -q)

echo "Testing Prometheus endpoints..."
for endpoint in "" "/graph" "/metrics" "/targets"; do
    echo "Testing http://localhost:9090${endpoint}"
    curl -IL "http://localhost:9090${endpoint}"
    echo "-------------------"
done
