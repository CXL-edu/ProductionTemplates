#!/bin/bash
# 容器启动入口脚本
# 此脚本在容器启动时自动执行，适用于所有场景（docker-compose、VS Code Dev Containers 等）

set -e

echo "=== 容器启动初始化 ==="

# 为所有用户（包括非 root）配置全局环境变量：
# 统一从 /workspace/.env 加载，而不是一个个手写 export。
echo "写入 /etc/profile.d/claude-env.sh（全局环境变量，自动加载 .env）..."
cat >/etc/profile.d/claude-env.sh <<'EOF'
# 为 Claude / MCP / 浏览器等工具提供统一的环境变量
# 该文件会在所有用户的登录 shell 中被自动加载

if [ -f /workspace/.env ]; then
  # 自动将 .env 中的 KEY=VALUE 形式导出为环境变量
  set -a
  . /workspace/.env
  set +a
fi
EOF
chmod +x /etc/profile.d/claude-env.sh || true

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

# 初始化 agent-browser（如果启用了浏览器 MCP）
# agent-browser 是一个独立的 CLI 工具，不是 MCP 服务器
# 文档: https://github.com/vercel-labs/agent-browser
if [ "$ENABLE_BROWSER_MCP" = "true" ] && command -v agent-browser &> /dev/null; then
    echo "初始化 agent-browser..."
    # agent-browser install 会检查并下载 Chromium（如果尚未安装）
    # 系统依赖已在 Dockerfile 中安装，所以不需要 --with-deps
    agent-browser install 2>/dev/null || echo "注意: agent-browser install 可能需要手动运行"

    # 为 Claude Code 安装 agent-browser 官方提供的 Skill
    # 参考文档中的示例命令：
    #   mkdir -p .claude/skills/agent-browser
    #   curl -o .claude/skills/agent-browser/SKILL.md \
    #     https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/SKILL.md
    if [ -d /workspace ]; then
        echo "为 Claude Code 安装 agent-browser Skill..."
        mkdir -p /workspace/.claude/skills/agent-browser
        if [ ! -f /workspace/.claude/skills/agent-browser/SKILL.md ]; then
            curl -fsSL \
              https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/SKILL.md \
              -o /workspace/.claude/skills/agent-browser/SKILL.md || \
              echo "警告: 下载 agent-browser Skill 说明失败，请参考官方文档手动安装。"
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
