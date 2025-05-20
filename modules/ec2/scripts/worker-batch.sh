#!/bin/bash

REGISTRY_IP="10.0.1.161:5000"
DOCKER_CONFIG_FILE="/etc/docker/daemon.json"

# 安裝 docker 套件
sudo apt update
sudo apt install -y docker.io

# 寫入設定
sudo tee "$DOCKER_CONFIG_FILE" > /dev/null <<EOF
{
  "insecure-registries": ["$REGISTRY_IP"]
}
EOF

sudo systemctl restart docker

# Join swarm manager
sudo docker swarm join --token SWMTKN-1-4u3e28fhntze328wvl9az8edy2ozberruzfizzkzbrhhycmpup-75mcyt7kfd4f28kggjvrakb71 10.0.1.161:2377