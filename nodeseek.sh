#!/bin/bash
set -e

echo "=== 🧩 开始安装 NodeSeek 环境 ==="

# 1. 创建工作目录
sudo mkdir -p /opt/NodeSeek
cd /opt/NodeSeek

# 2. 安装系统依赖
echo "=== 🧱 更新系统并安装依赖 ==="
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release python3 python3-venv python3-pip chromium libnss3 libnss3-tools libnspr4 libssl-dev libxss1 libgconf-2-4 fonts-liberation

# 3. 安装 Docker
echo "=== 🐳 安装 Docker ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker

# 4. 生成 Cloudflyer 密钥并保存
KEY=$(openssl rand -hex 16)
echo "$KEY" | sudo tee /opt/NodeSeek/cloudflyer_Key.txt
echo "Cloudflyer 秘钥: $KEY"

# 5. 运行 Cloudflyer 容器
echo "=== ☁️ 启动 Cloudflyer 容器 ==="
sudo docker run -itd \
  --name cloudflyer \
  -p 3000:3000 \
  --restart unless-stopped \
  jackzzs/cloudflyer \
  -K "$KEY" \
  -H 0.0.0.0

# 6. 运行 FlareSolverr 容器
echo "=== 🔥 启动 FlareSolverr 容器 ==="
sudo docker run -d \
  --name flaresolverr \
  --network host \
  -e LOG_LEVEL=info \
  --restart unless-stopped \
  ghcr.io/flaresolverr/flaresolverr:latest

# 7. 安装 Node.js
echo "=== 🧠 安装 Node.js 与 npm ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 8. 安装 Node 依赖
echo "=== 📦 安装 Node.js 依赖 ==="
npm install cloudscraper dayjs dotenv node-cron node-telegram-bot-api

# 9. 安装 Python 虚拟环境与依赖
echo "=== 🐍 设置 Python 虚拟环境 ==="
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install "python-telegram-bot[job-queue]" curl-cffi python-dotenv chromedriver-autoinstaller

# 10. 验证服务
echo "=== ✅ 验证服务是否正常 ==="
sleep 3
curl -s http://localhost:3000 && echo "Cloudflyer 运行正常 ✅" || echo "Cloudflyer 启动失败 ❌"
curl -s http://localhost:8191/health && echo "FlareSolverr 运行正常 ✅" || echo "FlareSolverr 启动失败 ❌"

echo "=== 🎉 部署完成 ==="
echo "Cloudflyer API 地址: http://localhost:3000"
echo "FlareSolverr API 地址: http://127.0.0.1:8191/v1"
echo "秘钥文件路径: /opt/NodeSeek/cloudflyer_Key.txt"
