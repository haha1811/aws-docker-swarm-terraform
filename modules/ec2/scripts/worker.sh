#!/bin/bash
# 安裝 Docker
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# 注意：這裡不自動 join Swarm，需手動執行 docker swarm join 指令
docker swarm join --token SWMTKN-1-4hapa8sermytvyqm8vx8ccpsg4c5z31bv3l2y9e528sdurtf5p-3gl4g0n7ril76bgj79gjqwkcj 10.0.1.207:2377
