#!/bin/bash
# 安裝 Docker
apt-get update -y
apt-get install -y docker.io net-tools mysql-client iputils-ping jq
systemctl start docker
systemctl enable docker

# 初始化 Swarm（設定為 Manager）


# EC2 導致重建的原因
#| 原因                                          | 結果                            |
#| ------------------------------------------- | ----------------------------- |
#| ✅ `user_data` 有變動（如腳本內容變更）                  | EC2 **會被 destroy + recreate** |

