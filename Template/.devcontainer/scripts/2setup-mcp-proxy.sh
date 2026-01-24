#!/bin/bash
# 轻量 MCP 代理初始化脚本
# 
# 作用说明：
# 此脚本用于解决某些 MCP 服务器使用 node fetch 时不走代理的问题。
# 通过生成 proxy-inject.js 脚本，使用 undici 的 ProxyAgent 为所有 Node.js 进程
# 设置全局代理分发器，确保 fetch 请求能够通过代理。
#
# 使用场景：
# - PROXY_MODE=auto 时：自动生成 proxy-inject.js，并通过 NODE_OPTIONS 注入到所有 Node 进程
# - PROXY_MODE=tun 时：不执行此脚本（TUN 模式是系统级透明代理，不需要应用层代理）
# - PROXY_MODE=none 时：不执行此脚本（无代理模式）
#
# 前提：通过 .env 设置了 HTTPS_PROXY / HTTP_PROXY 和 PROXY_MODE=auto

set -e

# 读取代理模式，默认为 auto（向后兼容）
PROXY_MODE="${PROXY_MODE:-auto}"

# 如果代理模式为 none 或 tun，则跳过
if [ "$PROXY_MODE" = "none" ] || [ "$PROXY_MODE" = "tun" ]; then
  echo "代理模式为 $PROXY_MODE，跳过 proxy-inject.js 生成（TUN 模式使用系统级代理，无需应用层代理）"
  exit 0
fi

# 如果代理模式不是 auto，也跳过（防止未知模式）
if [ "$PROXY_MODE" != "auto" ]; then
  echo "警告: 未知的代理模式 '$PROXY_MODE'，跳过 proxy-inject.js 生成"
  exit 0
fi

PROXY_URL="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy}}}}"

# 未配置代理时直接跳过
if [ -z "$PROXY_URL" ]; then
  echo "警告: PROXY_MODE=auto 但未配置代理地址，跳过 proxy-inject.js 生成"
  exit 0
fi

HOME_DIR="${HOME:-/root}"
PROXY_INJECT_SCRIPT="$HOME_DIR/proxy-inject.js"

cd "$HOME_DIR"

echo "配置 MCP 代理（PROXY_MODE=auto）..."

# 确保 undici 已安装（失败也不阻塞容器启动）
if [ ! -d "$HOME_DIR/node_modules/undici" ]; then
  echo "安装 undici 依赖..."
  npm init -y >/dev/null 2>&1 || true
  npm install undici >/dev/null 2>&1 || true
fi

cat > "$PROXY_INJECT_SCRIPT" <<EOF
// 全局 MCP 代理注入脚本（自动生成）
// 
// 作用：为所有 Node.js 进程设置全局代理分发器，确保使用 undici 的 fetch 能够通过代理
// 使用场景：解决某些 MCP 服务器使用 node fetch 时不走代理的问题
// 
// 注意：此脚本仅在 PROXY_MODE=auto 时生成和使用
//       PROXY_MODE=tun 时不会使用此脚本（TUN 模式是系统级透明代理）
const { setGlobalDispatcher, ProxyAgent } = require('${HOME_DIR}/node_modules/undici');

const proxyUrl =
  process.env.HTTPS_PROXY ||
  process.env.https_proxy ||
  process.env.HTTP_PROXY ||
  process.env.http_proxy ||
  '${PROXY_URL}';

const dispatcher = new ProxyAgent({
  uri: proxyUrl,
  connect: { rejectUnauthorized: false },
});

setGlobalDispatcher(dispatcher);
EOF

echo "已生成 proxy-inject.js: $PROXY_INJECT_SCRIPT"

