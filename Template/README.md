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
│   └── entrypoint.sh               # 容器启动入口脚本（自动初始化）
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

### MCP 配置（可选）
```bash
cp .mcp-config.sh.example .mcp-config.sh
# 编辑 .mcp-config.sh，取消注释并修改配置
```

容器启动时会自动执行 `.mcp-config.sh`（如果存在）。

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
