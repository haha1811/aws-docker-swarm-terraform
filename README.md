太好了！你想用 Terraform 建立一套可在 AWS 上執行 Docker Swarm 的 3-Tier 架構，並透過模組 (modules) 分別管理 VPC、EC2、EIP、NAT、Route Table 等資源，這是一個非常實用且可擴展的架構。

---

## ✅ 架構總覽

```
  Internet
     │
     ▼
[ Public Subnet ]
     │
     ├── EC2: Manager (有 Public IP, 可 SSH)
     └── NAT Gateway (讓 Worker 能上網)

[ Private Subnet ]
     ├── EC2: Worker1
     ├── EC2: Worker2
     └── EC2: Worker3
```

---

## 🧱 專案結構建議

```
terraform-docker-swarm/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── vpc/
│   ├── ec2/
│   ├── nat/
│   ├── eip/
│   └── route/
```

---

## 📁 `main.tf`

```hcl
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source     = "./modules/vpc"
  project    = var.project
  aws_region = var.aws_region  # ✅ 加這行
}

module "eip" {
  source = "./modules/eip"
}

module "nat" {
  source      = "./modules/nat"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnet_id
  eip_id      = module.eip.eip_id
}

module "route" {
  source         = "./modules/route"
  private_rt_id  = module.vpc.private_route_table_id
  nat_gateway_id = module.nat.nat_gateway_id
}

module "ec2" {
  source              = "./modules/ec2"
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  manager_key_pair    = var.key_pair_name
}
```

---

## 📁 `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  default = "docker-swarm-demo"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair to use"
}
```

---

## 📁 `outputs.tf`

```hcl
output "manager_public_ip" {
  value = module.ec2.manager_public_ip
}
```

---

## 📁 `terraform.tfvars`

```hcl
key_pair_name = "05004_lab_test_haha"
```

---

## 🔧 模組簡介（每個 module 詳細內容我可接著提供）

| 模組      | 功能                                             |
| ------- | ---------------------------------------------- |
| `vpc`   | 建立 VPC、Public/Private Subnet、Route Table       |
| `eip`   | 建立 NAT Gateway 專用的 EIP                         |
| `nat`   | 建立 NAT Gateway 並與 Public Subnet 綁定             |
| `route` | 將 Private Subnet route 設為 NAT Gateway          |
| `ec2`   | 建立 1 台 Manager、3 台 Worker，且安裝 Docker 並啟用 Swarm |

---

## 📌 下一步

我可以依序提供每個 module 的 `.tf` 實作內容，例如：

* `modules/vpc/main.tf`
* `modules/ec2/main.tf`（內含 user\_data 安裝 docker + swarm init/join）
* `modules/nat/main.tf`
* `modules/route/main.tf`

請問要從哪一個模組開始產出？還是我可以直接依照順序幫你產出所有模組內容？


---

所有 Terraform modules (`vpc`, `eip`, `nat`, `route`, `ec2`) 都已補齊至文件中。每個模組的主要內容如下：

* `vpc`：建立 VPC、subnets、route tables
* `eip`：分配 NAT Gateway 專用 EIP
* `nat`：建立 NAT Gateway
* `route`：在 private subnet 設定 NAT route
* `ec2`：部署 Manager + Worker EC2 並安裝 Docker/Swarm（user\_data scripts）

---

# === modules/vpc/main.tf ===
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.project}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.2.0/24", 2, count.index)
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.project}-private-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

# === modules/eip/main.tf ===
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

output "eip_id" {
  value = aws_eip.nat.id
}

# === modules/nat/main.tf ===
resource "aws_nat_gateway" "gw" {
  allocation_id = var.eip_id
  subnet_id     = var.subnet_id
  tags = {
    Name = "nat-gateway"
  }
  depends_on = [var.vpc_id]
}


# === modules/route/main.tf ===
resource "aws_route" "nat_route" {
  route_table_id         = var.private_rt_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# === modules/ec2/main.tf ===
resource "aws_instance" "manager" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_id
  key_name      = var.manager_key_pair
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  user_data = file("${path.module}/scripts/manager.sh")

  tags = {
    Name = "swarm-manager"
  }
}

resource "aws_instance" "workers" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.private_subnet_ids[count.index]
  key_name      = var.manager_key_pair
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  user_data = file("${path.module}/scripts/worker.sh")

  tags = {
    Name = "swarm-worker-${count.index}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

output "manager_public_ip" {
  value = aws_instance.manager.public_ip
}


# === modules/ec2/sg.tf ===
resource "aws_security_group" "swarm_sg" {
  name   = "swarm-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["210.64.53.104/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # ✅ 允許 all traffic
    cidr_blocks = ["10.0.0.0/16"]  # ✅ 僅限內部私有網段
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "swarm_sg"  # ✅ 加入標籤
  }
}

---

這個錯誤的根本原因是：

> 你在 `main.tf` 的 `module "nat"` 傳了變數 `vpc_id`、`subnet_id` 和 `eip_id`，但對應的 `modules/nat/main.tf` 裡沒有宣告這些變數，所以 Terraform 覺得這些參數是「Unsupported argument」。

---

## ✅ 解法：補上 `modules/nat/variables.tf`

你需要在 `modules/nat` 資料夾內建立一個 `variables.tf` 檔，內容如下：

```hcl
variable "vpc_id" {
  description = "VPC ID for NAT Gateway dependency"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID to associate the NAT Gateway"
  type        = string
}

variable "eip_id" {
  description = "Elastic IP allocation ID"
  type        = string
}
```

---

## 🔁 可選補強：也可以補上 `outputs.tf`

雖然這不是錯誤的根源，但最好一起補上，以供其他 module 使用：

`modules/nat/outputs.tf`：

```hcl
output "nat_gateway_id" {
  value = aws_nat_gateway.gw.id
}
```

---

## 📌 總結你需要的修正動作

| 位置             | 檔案             | 說明                                  |
| -------------- | -------------- | ----------------------------------- |
| `modules/nat/` | `variables.tf` | 宣告 `vpc_id`、`subnet_id`、`eip_id` 變數 |
| `modules/nat/` | `outputs.tf`   | 回傳 NAT Gateway ID 給其他模組使用           |

---

這個錯誤代表你在 `main.tf` 中傳入 `module "ec2"` 的這些參數：

* `vpc_id`
* `public_subnet_id`
* `private_subnet_ids`
* `manager_key_pair`

都沒有在 `modules/ec2/variables.tf` 宣告，因此 Terraform 無法辨識它們。

---

## ✅ 解法：補上 `modules/ec2/variables.tf`

請在 `modules/ec2/` 資料夾中建立 `variables.tf`，內容如下：

```hcl
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Subnet ID for Manager node"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnet IDs for Worker nodes"
  type        = list(string)
}

variable "manager_key_pair" {
  description = "Key pair for EC2 SSH login"
  type        = string
}
```

---

這個錯誤的原因和前面一樣，是因為：

> `module "route"` 中傳入了 `private_rt_id` 和 `nat_gateway_id` 這兩個參數，但你在 `modules/route/variables.tf` 裡面並**沒有宣告**這些變數。

---

## ✅ 解法：補上 `modules/route/variables.tf`

請在 `modules/route/` 目錄中新增或編輯 `variables.tf`，加入以下內容：

```hcl
variable "private_rt_id" {
  description = "Private route table ID"
  type        = string
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID"
  type        = string
}
```

---

你目前的錯誤是：

> ❌ `project = var.project` 在 `module "vpc"` 中被使用，但 `modules/vpc` 目錄下沒有定義 `variable "project"`，因此出現 `Unsupported argument` 錯誤。

---

## ✅ 解法：補上 `modules/vpc/variables.tf`

請建立或修改 `modules/vpc/variables.tf` 加入以下內容：

```hcl
variable "project" {
  description = "Project name prefix used for tagging resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region (e.g. ap-northeast-1)"
  type        = string
}
```

---

## ✅ 檢查整體 modules 建議對照表

| Module 名稱 | 必要 variables                                                           | 是否補齊        |
| --------- | ---------------------------------------------------------------------- | ----------- |
| `vpc`     | `project`                                                              | ⛔ 尚未補（剛剛補上） |
| `eip`     | 無（純資源建立）                                                               | ✅ 已處理       |
| `nat`     | `vpc_id`, `subnet_id`, `eip_id`                                        | ✅ 已補        |
| `route`   | `private_rt_id`, `nat_gateway_id`                                      | ✅ 已補        |
| `ec2`     | `vpc_id`, `public_subnet_id`, `private_subnet_ids`, `manager_key_pair` | ✅ 已補        |

---

你遇到的錯誤訊息：

> `Invalid value for "path" parameter: no file exists at "modules/ec2/scripts/manager.sh"`
> `Invalid value for "path" parameter: no file exists at "modules/ec2/scripts/worker.sh"`

這是因為 Terraform 找不到你在 `file(...)` 中指定的檔案路徑，這兩個腳本檔案實際上**尚未建立**。

---

## ✅ 解法：建立 `manager.sh` 與 `worker.sh` 腳本

請依照以下方式，在 `modules/ec2/scripts/` 資料夾中建立這兩個檔案。

---

### 📁 `modules/ec2/scripts/manager.sh`

```bash
#!/bin/bash
# 安裝 Docker
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# 初始化 Swarm（設定為 Manager）
docker swarm init
```

---

### 📁 `modules/ec2/scripts/worker.sh`

```bash
#!/bin/bash
# 安裝 Docker
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# 注意：這裡不自動 join Swarm，需手動執行 docker swarm join 指令
```

---

## 🧠 說明

| 腳本檔案         | 說明                                                |
| ------------ | ------------------------------------------------- |
| `manager.sh` | 初始化 Docker + 建立 Swarm（manager 節點）                 |
| `worker.sh`  | 安裝 Docker，後續你可手動 SSH 進去用 `docker swarm join` 加入集群 |

> 若你希望 **worker 自動 join**，我可以幫你實作傳入 `--token` + `--manager-ip` 的方式。

---

## ✅ 解法：在 AWS Cloud9 安裝 Terraform

請依照以下步驟操作：

### 📌 Step 1: 下載 Terraform CLI 最新版本

```bash
T_VERSION="1.7.5"
curl -O https://releases.hashicorp.com/terraform/${T_VERSION}/terraform_${T_VERSION}_linux_amd64.zip
```

### 📌 Step 2: 解壓縮並移動到 `/usr/local/bin`

```bash
unzip terraform_${T_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 📌 Step 3: 驗證 Terraform 是否安裝成功

```bash
terraform version
```

你應該會看到類似這樣的輸出：

```
Terraform v1.7.5
```

---



太好了！以下是你可以在 **Docker Swarm 架構中自架 Docker Registry** 的完整操作說明，適用於你目前的 AWS EC2 架構，方便集中管理所有 image，不必依賴 Docker Hub 或 AWS ECR。

---

## 🧱 目標架構圖

```
┌──────────────┐      ┌────────────────────┐
│  EC2 Manager │─────▶ Docker Registry     │
│  (Public IP) │      │ Port: 5000          │
└──────────────┘      └────────────────────┘
        │                    ▲
        ▼                    │
┌──────────────┐      ┌──────────────┐
│ EC2 Worker 1 │◀────▶│ Pull images  │
│ EC2 Worker 2 │◀────▶│ from manager │
│ EC2 Worker 3 │◀────▶│ registry     │
└──────────────┘      └──────────────┘
```

---

## 🛠️ 安裝步驟（在 Manager EC2 上）

### Step 1：建立本地 Registry 容器

```bash
docker run -d \
  --name registry \
  --restart=always \
  -p 5000:5000 \
  registry:2
```

這會建立一個可用於 Push/Pull 的私有 Registry，開在 port 5000。

---

### Step 2：所有 EC2 節點（包括自己）都要信任這個 Registry

因為這是沒有 TLS 的 registry（除非你加 SSL 憑證），所以需加到 daemon 配置。

#### 修改 `/etc/docker/daemon.json`：

```json
{
  "insecure-registries": ["<manager-private-ip>:5000"]
}
```

👉 範例：

```json
{
  "insecure-registries": ["172.31.25.10:5000"]
}
```

#### 重啟 Docker：

```bash
sudo systemctl restart docker
```

---

### Step 3：Build 並 Push Image 到本地 Registry（只在 Manager 操作）

```bash
docker build -t myapp .

# Tag 為本地 Registry 用法
docker tag myapp <manager-private-ip>:5000/myapp

# Push 到私有 Registry
docker push <manager-private-ip>:5000/myapp
```

---

### Step 4：在 Swarm 使用該 image

#### docker-compose.yml：

```yaml
version: "3.9"
services:
  web:
    image: <manager-private-ip>:5000/myapp
    deploy:
      replicas: 3
      placement:
        constraints: [node.role == worker]
    ports:
      - "80:80"
```

#### 部署：

```bash
docker stack deploy -c docker-compose.yml myapp
```

---

## 🔐 進階（推薦）

若你打算長期使用私有 registry，建議加入：

### ✅ 使用 Nginx Reverse Proxy + Let's Encrypt TLS：

* `docker-registry` 不建議長期使用 `--insecure-registries`
* 可加上 `nginx` SSL proxy 來包裝 registry（可配合 Certbot 自動簽憑證）

---

## 📦 實用指令總覽

| 操作               | 指令範例                                              |
| ---------------- | ------------------------------------------------- |
| 啟動 Registry      | `docker run -d -p 5000:5000 registry:2`           |
| 設定不安全 registry   | 編輯 `daemon.json` 並重啟 Docker                       |
| 建立 image         | `docker build -t myapp .`                         |
| Tag 為私有 registry | `docker tag myapp <IP>:5000/myapp`                |
| 上傳 image         | `docker push <IP>:5000/myapp`                     |
| 撰寫部署檔            | `docker-compose.yml` 指定私有 image                   |
| Stack 部署         | `docker stack deploy -c docker-compose.yml myapp` |

---

你可以透過以下幾種方式查看你自建的 Docker Registry 上有哪些已上傳的 image。

---

## ✅ 前提：你使用的自建 Registry 是官方映像 `registry:2`

例如：

```bash
docker run -d -p 5000:5000 --name registry registry:2
```

---

## 🔍 方法 1：使用 `curl` 查詢 Registry HTTP API

### 🔧 查詢 image repository 列表：

```bash
curl http://<registry-host>:5000/v2/_catalog
```

範例輸出：

```json
{
  "repositories": [
    "myapp",
    "nginx",
    "node"
  ]
}
```

---

### 🔧 查詢某個 image 有哪些 tags：

```bash
curl http://<registry-host>:5000/v2/<image-name>/tags/list
```

範例：

```bash
curl http://localhost:5000/v2/myapp/tags/list
```

範例輸出：

```json
{
  "name": "myapp",
  "tags": ["v1", "v2", "latest"]
}
```

---

## 🧪 如果你是在 Docker Swarm manager 上執行，且 registry 是本機：

用內部 IP 或 `localhost` 查詢：

```bash
curl http://localhost:5000/v2/_catalog
```

---

## 📌 其他補充工具（可選）

你也可以用這些開源工具提供 Web UI 管理：

| 工具名稱                                                              | 說明                    |
| ----------------------------------------------------------------- | --------------------- |
| [Portus](https://github.com/SUSE/Portus)                          | Web UI + 身分驗證功能       |
| [Docker Registry UI](https://github.com/Joxit/docker-registry-ui) | 輕量化 Web UI            |
| [Harbor](https://goharbor.io/)                                    | 功能最完整的企業級 registry UI |

---

你目前用 `curl` 查出來的結果是 JSON 沒錯，但它是「壓縮過的一行」，你想讓它「格式化漂亮地顯示」，有幾種方式可以做到：

---

## ✅ 方法 1：加上 `jq`（最推薦）

`jq` 是一個輕量又強大的 CLI JSON 處理器，Ubuntu 可直接安裝並使用。

### 🔧 安裝 `jq`：

```bash
sudo apt-get update
sudo apt-get install -y jq
```

### 🔍 用法範例：

```bash
sudo curl -s http://10.0.1.207:5000/v2/_catalog | jq
```

輸出：

```json
{
  "repositories": [
    "ap-image",
    "mysql-image",
    "web-image"
  ]
}
```

或：

```bash
sudo curl -s http://10.0.1.207:5000/v2/ap-image/tags/list | jq
```

---

## ✅ 方法 2：用 `python3 -m json.tool`（如果你沒 jq）

```bash
sudo curl -s http://10.0.1.207:5000/v2/_catalog | python3 -m json.tool
```

或：

```bash
sudo curl -s http://10.0.1.207:5000/v2/ap-image/tags/list | python3 -m json.tool
```

---

## 📌 補充：加 `-s` 參數避免多餘進度條干擾

`-s`（silent）可讓 curl 輸出更乾淨、更好配合 `jq` 或 `json.tool`

---

## 🎯 結果比較

| 指令     | 輸出格式                   |             |
| ------ | ---------------------- | ----------- |
| `curl` | 一行壓縮 JSON              |             |
| \`curl | jq\`                   | 美化格式 JSON ✅ |
| \`curl | python3 -m json.tool\` | 美化格式 JSON ✅ |

---

你已經將 image `mysql-image:latest` 推送到你的自建 Docker Registry（在 `10.0.1.207:5000`）上，因此你在建立 Docker Swarm service 時，**需要指定完整的 registry 路徑**。

---

## ✅ 修改後的指令如下：

```bash
sudo docker service create \
  --name mysql \
  --network mynet \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=Dev12876266 \
  10.0.1.207:5000/mysql-image:latest
```

---

## 🔍 為什麼要加 `10.0.1.207:5000/`？

這樣才能告訴 Swarm 去 **你的私有 registry** 抓 image，而不是預設去 Docker Hub 上找 `mysql-image`。

---

## ✅ 若你還沒信任這個 registry（worker 也要）

每台 Swarm 節點（manager + 所有 worker）都要設定 `daemon.json`：

```bash
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["10.0.1.207:5000"]
}
EOF

sudo systemctl restart docker
```

> 若沒設定 `insecure-registries`，你可能會遇到錯誤 `x509: certificate signed by unknown authority`

---

## 🧪 檢查服務是否啟動成功

```bash
sudo docker service ls
```

查看MySQL分配在哪台主機上執行：

```bash
sudo docker service ps mysql
```

---





---

