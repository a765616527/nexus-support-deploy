#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

read_dotenv_value() {
  local key="$1"
  if [ ! -f ".env" ]; then
    return 0
  fi

  local line
  line="$(grep -E "^${key}=" .env | tail -n 1 || true)"
  line="${line#*=}"
  line="${line%\"}"
  line="${line#\"}"
  printf "%s" "$line"
}

generate_secret() {
  local length="${1:-64}"

  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 64 | tr -d '\n' | cut -c1-"$length"
    return 0
  fi

  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

echo "[INFO] 开始部署客服系统..."

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] 未检测到 Docker。请先安装 Docker 和 Docker Compose 后重试。"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker 服务未运行。请先启动 Docker 后重试。"
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "[ERROR] 未检测到 Docker Compose。请先安装 Docker 和 Docker Compose 后重试。"
  exit 1
fi

DEPLOY_ROOT_DIR="/root/nexus-support"
if [ -d "$DEPLOY_ROOT_DIR" ]; then
  echo "[WARN] 检测到已安装目录：$DEPLOY_ROOT_DIR"
  echo "[WARN] 系统可能已经安装过。"
  echo "[WARN] 如需重新安装，请先执行以下任一操作后再重试："
  echo "       1) 修改目录名"
  echo "       2) 删除目录"
  echo "       3) 移动目录到其他位置"
  exit 1
fi

MYSQL_DATA_DIR="${MYSQL_DATA_DIR:-$DEPLOY_ROOT_DIR/mysql}"
mkdir -p "$MYSQL_DATA_DIR"
echo "[INFO] 系统根目录：$DEPLOY_ROOT_DIR"
echo "[INFO] MySQL 数据目录：$MYSQL_DATA_DIR"

APP_IMAGE_VALUE="arxuan123/nexus-support:latest"

DEFAULT_ADMIN_ACCOUNT="${ADMIN_ACCOUNT:-$(read_dotenv_value "ADMIN_ACCOUNT")}"
DEFAULT_ADMIN_NICKNAME="${ADMIN_NICKNAME:-$(read_dotenv_value "ADMIN_NICKNAME")}"

if [ -z "$DEFAULT_ADMIN_ACCOUNT" ]; then
  DEFAULT_ADMIN_ACCOUNT="admin"
fi
if [ -z "$DEFAULT_ADMIN_NICKNAME" ]; then
  DEFAULT_ADMIN_NICKNAME="超级管理员"
fi

read -r -p "[INPUT] 管理员账号 [${DEFAULT_ADMIN_ACCOUNT}]: " ADMIN_ACCOUNT_INPUT
ADMIN_ACCOUNT_VALUE="${ADMIN_ACCOUNT_INPUT:-$DEFAULT_ADMIN_ACCOUNT}"

while true; do
  read -r -s -p "[INPUT] 管理员密码: " ADMIN_PASSWORD_VALUE
  echo
  if [ -n "$ADMIN_PASSWORD_VALUE" ]; then
    break
  fi
  echo "[WARN] 管理员密码不能为空，请重新输入。"
done

read -r -p "[INPUT] 管理员昵称 [${DEFAULT_ADMIN_NICKNAME}]: " ADMIN_NICKNAME_INPUT
ADMIN_NICKNAME_VALUE="${ADMIN_NICKNAME_INPUT:-$DEFAULT_ADMIN_NICKNAME}"

SESSION_SECRET_VALUE="$(generate_secret 64)"
AES_SECRET_VALUE="$(generate_secret 64)"

echo "[INFO] 已生成 SESSION_SECRET 和 AES_SECRET。"

echo "[INFO] 拉取镜像..."
MYSQL_DATA_DIR="$MYSQL_DATA_DIR" \
APP_IMAGE="$APP_IMAGE_VALUE" \
ADMIN_ACCOUNT="$ADMIN_ACCOUNT_VALUE" \
ADMIN_PASSWORD="$ADMIN_PASSWORD_VALUE" \
ADMIN_NICKNAME="$ADMIN_NICKNAME_VALUE" \
SESSION_SECRET="$SESSION_SECRET_VALUE" \
AES_SECRET="$AES_SECRET_VALUE" \
"${COMPOSE_CMD[@]}" pull

echo "[INFO] 启动服务..."
MYSQL_DATA_DIR="$MYSQL_DATA_DIR" \
APP_IMAGE="$APP_IMAGE_VALUE" \
ADMIN_ACCOUNT="$ADMIN_ACCOUNT_VALUE" \
ADMIN_PASSWORD="$ADMIN_PASSWORD_VALUE" \
ADMIN_NICKNAME="$ADMIN_NICKNAME_VALUE" \
SESSION_SECRET="$SESSION_SECRET_VALUE" \
AES_SECRET="$AES_SECRET_VALUE" \
"${COMPOSE_CMD[@]}" up -d

echo "[INFO] 当前容器状态："
MYSQL_DATA_DIR="$MYSQL_DATA_DIR" \
APP_IMAGE="$APP_IMAGE_VALUE" \
"${COMPOSE_CMD[@]}" ps

HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [ -z "$HOST_IP" ]; then
  HOST_IP="localhost"
fi

echo
echo "[INFO] 本次部署生成的密钥（请妥善保存）："
echo "SESSION_SECRET=${SESSION_SECRET_VALUE}"
echo "AES_SECRET=${AES_SECRET_VALUE}"
echo
echo "[DONE] 部署完成。登录地址如下："
echo "用户登录：http://${HOST_IP}:3000/login"
echo "客服登录：http://${HOST_IP}:3000/login/agent"
echo "管理员登录：http://${HOST_IP}:3000/login/admin"
