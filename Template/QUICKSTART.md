# 快速开始指南

## 🎯 4 步创建新项目

### 1️⃣ 复制模板
```bash
cp -r /root/projects/datain/Template /root/projects/datain/你的项目名
cd /root/projects/datain/你的项目名
```

### 2️⃣ 修改项目名称
```bash
sed -i 's/PROJECT_NAME/你的项目名/g' docker compose.yml
sed -i 's/PROJECT_NAME/你的项目名/g' .devcontainer/devcontainer.json
```

### 3️⃣ 配置环境变量
```bash
cp .env.example .env
# 编辑 .env，设置 ANTHROPIC_AUTH_TOKEN=你的令牌
```

### 4️⃣ 启动容器
```bash
docker compose up -d --build
```

## ✅ 验证

```bash
docker compose ps
docker exec -it 你的项目名-claude-code /bin/bash
claude-code --version
```

## 📖 详细文档

查看 `README.md` 获取更多信息。
