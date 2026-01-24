#!/bin/bash
# 下载 Miniforge 安装包到 assets 目录
# 使用方法: bash .devcontainer/scripts/download_miniforge.sh
# 版本可以通过环境变量 MINIFORGE_VERSION 指定，或从 .env 文件读取

set -e

# 尝试从 .env 文件读取版本（如果存在）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
    # 从 .env 文件读取 MINIFORGE_VERSION
    ENV_VERSION=$(grep "^MINIFORGE_VERSION=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
    if [ -n "$ENV_VERSION" ]; then
        MINIFORGE_VERSION="$ENV_VERSION"
    fi
fi

# 使用环境变量或默认值
MINIFORGE_VERSION="${MINIFORGE_VERSION:-25.11.0-1}"
ASSETS_DIR="$(dirname "$(dirname "$0")")/../assets"
ARCH=$(uname -m)

# 确定架构
if [ "$ARCH" = "x86_64" ]; then
    MINIFORGE_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    MINIFORGE_ARCH="aarch64"
else
    echo "错误: 不支持的架构: $ARCH"
    exit 1
fi

MINIFORGE_FILENAME="Miniforge3-${MINIFORGE_VERSION}-Linux-${MINIFORGE_ARCH}.sh"
MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/${MINIFORGE_FILENAME}"
TARGET_FILE="${ASSETS_DIR}/${MINIFORGE_FILENAME}"

# 创建 assets 目录（如果不存在）
mkdir -p "$ASSETS_DIR"

# 检查文件是否已存在
if [ -f "$TARGET_FILE" ]; then
    echo "文件已存在: $TARGET_FILE"
    echo "跳过下载。如需重新下载，请先删除该文件。"
    exit 0
fi

echo "开始下载 Miniforge..."
echo "版本: $MINIFORGE_VERSION"
echo "架构: $MINIFORGE_ARCH"
echo "URL: $MINIFORGE_URL"
echo "目标文件: $TARGET_FILE"
echo ""

# 下载文件（带重试机制）
for i in 1 2 3; do
    if wget --quiet --no-check-certificate --timeout=30 --tries=3 "${MINIFORGE_URL}" -O "$TARGET_FILE"; then
        echo "下载成功！"
        echo "文件已保存到: $TARGET_FILE"
        ls -lh "$TARGET_FILE"
        exit 0
    else
        echo "下载失败，重试 $i/3..."
        if [ $i -lt 3 ]; then
            sleep 2
        fi
    fi
done

echo "错误: 无法下载 Miniforge，请检查网络连接"
exit 1
