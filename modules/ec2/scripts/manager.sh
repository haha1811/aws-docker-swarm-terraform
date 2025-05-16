#!/bin/bash
# 安裝 Docker
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# 初始化 Swarm（設定為 Manager）
docker swarm init
