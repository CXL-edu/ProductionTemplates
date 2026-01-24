#!/bin/bash
# MCP 配置脚本示例
# 
# 使用方法：
# 1. 复制此文件为 .mcp-config.sh
# 2. 取消注释并修改下面的 MCP 服务器配置
# 3. 容器启动时会自动执行此脚本

# 示例：添加 web-search-prime MCP 服务器
# claude mcp add -s user -t http web-search-prime \
#   https://open.bigmodel.cn/api/mcp/web_search_prime/mcp \
#   --header "Authorization: Bearer YOUR_TOKEN_HERE"

# 示例：添加更多 MCP 服务器
# claude mcp add -s user -t http another-mcp \
#   https://example.com/mcp \
#   --header "Authorization: Bearer YOUR_TOKEN"

# 配置 Brave Search MCP 服务器（使用 npx）
# 对应 MCP JSON 配置中 brave-search-mcp-server 的定义
# 环境变量 BRAVE_API_KEY 从 .env 文件读取
if [ -n "$BRAVE_API_KEY" ] && [ "$BRAVE_API_KEY" != "YOUR_API_KEY_HERE" ]; then
    echo "配置 Brave Search MCP 服务器（全局用户级）..."
    claude mcp add -s user --transport stdio brave-search-mcp-server \
        --env BRAVE_API_KEY="$BRAVE_API_KEY" \
        -- npx -y @brave/brave-search-mcp-server --transport stdio
fi

# 配置 GitHub MCP 服务器（通过 Docker 运行）
# 环境变量 GITHUB_PERSONAL_ACCESS_TOKEN 从 .env 文件读取
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "YOUR_GITHUB_TOKEN_HERE" ]; then
    echo "配置 GitHub MCP 服务器（全局用户级）..."
    claude mcp add -s user --transport stdio github \
        --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
        -- docker run -i --rm \
            -e GITHUB_PERSONAL_ACCESS_TOKEN \
            ghcr.io/github/github-mcp-server
fi

# 配置浏览器相关的 MCP 服务器
# 环境变量 ENABLE_BROWSER_MCP 从 .env 文件读取
if [ "$ENABLE_BROWSER_MCP" = "true" ]; then
    echo "配置浏览器相关的 MCP 服务器..."
    
    # 配置 Chrome DevTools MCP 服务器
    # 提供 Chrome DevTools 功能，用于浏览器自动化、调试和性能分析
    # 文档: https://github.com/ChromeDevTools/chrome-devtools-mcp
    if command -v npx &> /dev/null; then
        echo "配置 Chrome DevTools MCP 服务器（全局用户级）..."
        claude mcp add -s user --transport stdio chrome-devtools \
            -- npx -y chrome-devtools-mcp@latest
    fi
else
    echo "跳过浏览器 MCP 配置（ENABLE_BROWSER_MCP=false）"
fi

echo "MCP 配置脚本已执行（如果已配置）"
