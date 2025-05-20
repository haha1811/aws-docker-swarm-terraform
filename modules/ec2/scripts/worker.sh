#!/bin/bash
# 安裝 Docker
apt-get update -y
apt-get install -y docker.io net-tools iputils-ping jq
systemctl start docker
systemctl enable docker

# 注意：這裡不自動 join Swarm，需手動執行 docker swarm join 指令


# EC2 導致重建的原因
#| 原因                                          | 結果                            |
#| ------------------------------------------- | ----------------------------- |
#| ✅ `user_data` 有變動（如腳本內容變更）                  | EC2 **會被 destroy + recreate** |