# 项目模板 (Template)

Docker 容器项目模板，用于快速创建新的开发环境。

## 📁 模板结构

```
Template/
├── docker compose.yml              # Docker Compose 配置文件
├── .env.example                    # 环境变量配置示例文件
├── .mcp-config.sh.example          # MCP 配置脚本示例
├── .gitignore                      # Git 忽略规则
├── .devcontainer/                  # 开发容器配置目录
│   ├── Dockerfile                  # 容器镜像定义（已配置国内镜像源）
│   ├── devcontainer.json           # VS Code 开发容器配置
│   ├── entrypoint.sh               # 容器启动入口脚本（自动初始化）
│   └── setup-mcp-proxy.sh          # MCP 代理自动配置脚本
├── README.md                       # 完整文档
└── QUICKSTART.md                   # 快速开始指南
```

## 🚀 快速开始

### 1. 复制模板
```bash
cp -r /root/projects/datain/Template /root/projects/datain/你的项目名
cd /root/projects/datain/你的项目名
```

### 2. 修改项目名称
```bash
sed -i 's/PROJECT_NAME/你的项目名/g' docker compose.yml
sed -i 's/PROJECT_NAME/你的项目名/g' .devcontainer/devcontainer.json
```

### 3. 配置环境变量
```bash
cp .env.example .env
# 编辑 .env 文件，设置 ANTHROPIC_AUTH_TOKEN
```

### 4. 启动容器
```bash
docker compose up -d --build
```

## 📝 常用命令

```bash
# 启动/停止
docker compose up -d
docker compose down

# 查看日志
docker compose logs -f

# 进入容器
docker exec -it 你的项目名-claude-code /bin/bash
```

## 🔧 配置说明

### 环境变量 (.env)
- `ANTHROPIC_AUTH_TOKEN`: Claude API 认证令牌（必需）
- `ANTHROPIC_BASE_URL`: API 基础 URL（可选）
- `GIT_USER_NAME`: Git 用户名（可选）
- `GIT_USER_EMAIL`: Git 邮箱（可选）
- `PROXY_MODE`: 代理模式（可选，默认 `auto`）
  - `none`: 无代理模式，不使用任何代理
  - `auto`: 自动代理模式，使用 `HTTP_PROXY`/`HTTPS_PROXY` 环境变量配置的代理，并自动为 MCP 服务器注入代理支持（通过 `proxy-inject.js` 脚本，解决某些 MCP 使用 node fetch 不走代理的问题）
  - `tun`: TUN 模式，使用系统级透明代理（如 Clash TUN 模式），不需要应用层代理配置
    - 注意：TUN 模式下不会使用 `proxy-inject.js`，因为系统级代理已自动处理所有流量
- `HTTPS_PROXY` / `HTTP_PROXY`: 代理地址（仅在 `PROXY_MODE=auto` 时生效）
  - 示例: `HTTPS_PROXY=http://127.0.0.1:7890`
- `DOCKER_VOLUMES_PATH`: Docker Volumes 挂载路径（可选）
  - **默认行为**：如果不设置此变量，容器会自动使用项目目录下的相对路径 `./docker-volumes`
  - **自定义路径**：如果项目目录下没有 `docker-volumes` 文件夹，可以在 `.env` 中设置此变量为绝对路径
  - 示例: `DOCKER_VOLUMES_PATH=/root/project/docker-volumes`
  - **推荐**：如果项目目录下存在 `docker-volumes` 文件夹，建议不设置此变量，使用默认的相对路径，这样配置更便于开源和移植

### Miniforge (Conda) 环境
容器已预装 Miniforge（轻量级 conda 发行版），默认使用 conda-forge channel。

**使用示例：**
```bash
# 进入容器
docker exec -it 你的项目名-claude-code /bin/bash

# conda 环境已自动激活，可以直接使用
conda --version
conda list

# 创建新环境
conda create -n myenv python=3.11

# 激活环境
conda activate myenv

# 安装包
conda install numpy pandas matplotlib

# 或使用 pip（在 conda 环境中）
pip install some-package
```

**已配置国内镜像源：**
- 已配置清华大学 conda 镜像源，加速包下载
- 默认使用 conda-forge channel（更丰富的包选择）

### MCP 配置（可选）
```bash
cp .mcp-config.sh.example .mcp-config.sh
# 编辑 .mcp-config.sh，取消注释并修改配置
```

容器启动时会自动执行 `.mcp-config.sh`（如果存在）。

### MCP 代理自动配置（网络问题）

如果 MCP 报 `fetch failed` 等网络错误，需要根据你的代理类型选择合适的代理模式：

#### 自动代理模式（PROXY_MODE=auto，默认）

适用于使用 HTTP/HTTPS 代理（如 Clash、V2Ray 等）的场景：

```bash
PROXY_MODE=auto
HTTPS_PROXY=http://127.0.0.1:7890
HTTP_PROXY=http://127.0.0.1:7890
```

容器启动时会自动：
- 安装 `undici`（如未安装）
- 生成 `proxy-inject.js`（用于解决某些 MCP 使用 node fetch 不走代理的问题）
- 设置全局 `NODE_OPTIONS`，让所有 Node.js MCP 自动走代理

**proxy-inject.js 的作用说明：**
- 某些 MCP 服务器使用 Node.js 的 `fetch` API 时，不会自动读取 `HTTP_PROXY`/`HTTPS_PROXY` 环境变量
- 通过 `proxy-inject.js` 脚本，使用 undici 的 `ProxyAgent` 为所有 Node.js 进程设置全局代理分发器
- 确保所有使用 undici 的 fetch 请求都能通过代理

#### TUN 模式（PROXY_MODE=tun）

适用于使用系统级透明代理（如 Clash TUN 模式）的场景：

```bash
PROXY_MODE=tun
```

**注意：**
- TUN 模式是系统级透明代理，所有网络流量会自动通过代理，无需应用层配置
- TUN 模式下**不会**使用 `proxy-inject.js`，因为系统级代理已自动处理所有流量
- 需要在 Clash 配置中启用 TUN 模式（参考相关文档）

#### 无代理模式（PROXY_MODE=none）

```bash
PROXY_MODE=none
```

`.claude.json` 不需要写任何代理相关配置。

## ⚠️ 注意事项

1. 确保容器名称和网络名称唯一，避免冲突
2. `.env` 和 `.mcp-config.sh` 包含敏感信息，已在 `.gitignore` 中
3. 容器启动时会自动初始化 Git、Claude Code 和 MCP 配置

## 🆘 故障排查

```bash
# 查看日志
docker compose logs

# 检查配置
docker compose config

# 验证容器
docker exec 你的项目名-claude-code claude-code --version
```
