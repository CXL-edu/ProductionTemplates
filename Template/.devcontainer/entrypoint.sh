#!/bin/bash
# 容器启动入口脚本
# 此脚本在容器启动时自动执行，适用于所有场景（docker-compose、VS Code Dev Containers 等）

set -e

echo "=== 容器启动初始化 ==="

# 配置 Git（如果环境变量存在）
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    echo "配置 Git 用户信息..."
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
fi

# 配置 Claude Code 的 onboarding（如果未完成）
if [ ! -f ~/.claude.json ] || ! grep -q "hasCompletedOnboarding" ~/.claude.json 2>/dev/null; then
    echo "初始化 Claude Code 配置..."
    mkdir -p ~/.claude
    if [ ! -f ~/.claude.json ]; then
        echo '{"hasCompletedOnboarding": true}' > ~/.claude.json
    else
        # 使用 jq 添加配置（如果已安装）
        if command -v jq &> /dev/null; then
            jq '.hasCompletedOnboarding = true' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
        else
            # 如果没有 jq，简单追加（不完美但可用）
            echo '{"hasCompletedOnboarding": true}' > ~/.claude.json
        fi
    fi
fi

# 配置 MCP 服务器（如果存在配置文件）
if [ -f /workspace/.mcp-config.sh ]; then
    echo "执行项目 MCP 配置脚本..."
    bash /workspace/.mcp-config.sh
fi

echo "=== 初始化完成 ==="

# 执行传入的命令（默认是 sleep infinity）
exec "$@"
