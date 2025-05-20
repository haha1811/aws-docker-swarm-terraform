#!/bin/bash

# 變數設定
REGISTRY_IP="10.0.1.161"

# MySQL image build
docker image build -t mysql-image -f Dockerfile.mysql .

# AP image build
docker image build -t web-image -f Dockerfile.php .

# WEB image build
docker image build -t ap-image -f Dockerfile.web .

# MySQL image tag
docker tag mysql-image $REGISTRY_IP:5000/mysql-image

# AP image tag
docker tag ap-image $REGISTRY_IP:5000/ap-image

# WEB image tag
docker tag web-image $REGISTRY_IP:5000/web-image

# MySQL image push
docker push $REGISTRY_IP:5000/mysql-image

# AP image push
docker push $REGISTRY_IP:5000/ap-image

# WEB image push
docker push $REGISTRY_IP:5000/web-image

apt install -y jq
docker images
curl http://$REGISTRY_IP:5000/v2/_catalog | jq
