#!/bin/bash
# 容器启动入口脚本
# 此脚本在容器启动时自动执行，适用于所有场景（docker-compose、VS Code Dev Containers 等）

set -e

echo "=== 容器启动初始化 ==="

# 初始化 conda 环境（如果已安装）
if [ -f /opt/conda/etc/profile.d/conda.sh ]; then
    echo "初始化 conda 环境..."
    source /opt/conda/etc/profile.d/conda.sh
    conda activate base
    echo "conda 环境已激活"
fi

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
    echo '{"hasCompletedOnboarding": true}' > ~/.claude.json
fi

# 执行初始化脚本
# 使用与 docker-compose.yml 中挂载路径一致的目录
CLASH_DIR="$HOME/clash"
if [ -f /workspace/.devcontainer/scripts/0clash_script.sh ]; then
    if [ ! -f "$CLASH_DIR/clash" ] || [ ! -f "$CLASH_DIR/config.yaml" ]; then
        bash /workspace/.devcontainer/scripts/0clash_script.sh || true
    fi
    if [ -f "$CLASH_DIR/clash" ] && [ -f "$CLASH_DIR/config.yaml" ] && ! pgrep -f "clash.*-d" > /dev/null; then
        cd "$CLASH_DIR" && nohup ./clash -d . > clash.log 2>&1 &
    fi
fi

if [ -f /workspace/.devcontainer/scripts/1tool_install.sh ]; then
    bash /workspace/.devcontainer/scripts/1tool_install.sh || true
    source ~/.bashrc 2>/dev/null || true
fi

# 根据代理模式配置 MCP 代理
# 读取代理模式，默认为 auto（向后兼容）
PROXY_MODE="${PROXY_MODE:-auto}"

if [ "$PROXY_MODE" = "auto" ] && [ -f /workspace/.devcontainer/scripts/2setup-mcp-proxy.sh ]; then
    # 自动代理模式：生成 proxy-inject.js 并注入到所有 Node 进程
    # 作用：解决某些 MCP 服务器使用 node fetch 时不走代理的问题
    # 通过 undici 的 ProxyAgent 为所有 Node.js 进程设置全局代理分发器
    echo "配置 MCP 代理（PROXY_MODE=auto）..."
    bash /workspace/.devcontainer/scripts/2setup-mcp-proxy.sh || true
    
    # 检查 proxy-inject.js 是否已生成（脚本内部会根据条件决定是否生成）
    if [ -f "${HOME:-/root}/proxy-inject.js" ]; then
        export NODE_OPTIONS="--require ${HOME:-/root}/proxy-inject.js"
        export NODE_TLS_REJECT_UNAUTHORIZED=0
        echo "已设置 NODE_OPTIONS 以启用 proxy-inject.js"
    fi
elif [ "$PROXY_MODE" = "tun" ]; then
    # TUN 模式：系统级透明代理，不需要应用层代理配置
    # 注意：TUN 模式下不会使用 proxy-inject.js，因为系统级代理已自动处理所有流量
    echo "代理模式为 TUN（系统级透明代理），跳过 proxy-inject.js 配置"
elif [ "$PROXY_MODE" = "none" ]; then
    # 无代理模式
    echo "代理模式为 none（无代理），跳过代理配置"
else
    echo "警告: 未知的代理模式 '$PROXY_MODE'，跳过代理配置"
fi

# 配置 MCP 服务器（如果存在配置文件）
if [ -f /workspace/.devcontainer/scripts/3mcp-config.sh ]; then
    bash /workspace/.devcontainer/scripts/3mcp-config.sh
elif [ -f /workspace/.mcp-config.sh ]; then
    bash /workspace/.mcp-config.sh
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

echo "=== 初始化完成 ==="

# 执行传入的命令（默认是 sleep infinity）
exec "$@"
