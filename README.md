# Nexus Support Deploy

这个仓库只包含部署 `nexus-support` 所需文件，不包含业务源码。

## 包含内容

- `deploy.sh`：一键部署脚本
- `docker-compose.yml`：服务编排（MySQL + nexus-support + watchtower）
- `docker/mysql/init/01-shadow-db.sh`：MySQL 初始化脚本（自动创建 shadow 库并授权）

## 部署前准备

- 已安装 Docker
- 已安装 Docker Compose（`docker compose` 或 `docker-compose`）
- 服务器可访问 DockerHub

## 一键部署

```bash
git clone https://github.com/a765616527/nexus-support-deploy.git
cd nexus-support-deploy
chmod +x deploy.sh
./deploy.sh
```

脚本会自动：

1. 检查 Docker / Docker Compose
2. 检查是否已安装（`/root/nexus-support` 目录）
3. 要求输入管理员账号、密码、昵称
4. 自动生成 `SESSION_SECRET` 和 `AES_SECRET`
5. 启动容器：
   - `nexus-support-mysql`
   - `nexus-support-app`
   - `nexus-support-watchtower`
6. 输出登录地址

## 默认镜像

部署脚本已固定使用以下镜像：

- `arxuan123/nexus-support:latest`

如需改镜像版本，请直接修改 `deploy.sh` 中的 `APP_IMAGE_VALUE`。

## 登录入口

部署完成后可访问：

- 用户：`http://<服务器IP>:3000/login`
- 客服：`http://<服务器IP>:3000/login/agent`
- 管理员：`http://<服务器IP>:3000/login/admin`

## 升级方式

### 方式一：自动升级（推荐）

`watchtower` 已开启，默认每 60 秒检查一次新镜像并自动滚动重启。

### 方式二：手动升级

```bash
docker compose pull
docker compose up -d
```

## 卸载

```bash
docker compose down
```

如果你要彻底删除 MySQL 数据：

```bash
rm -rf /root/nexus-support
```
