FROM node:20-slim

# ============================================
# 配置国内镜像源以加速下载
# ============================================

# 配置 apt 国内镜像源（阿里云镜像）
# 优先尝试修改 debian.sources，如果失败则创建 sources.list
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources || \
    (echo "deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
     echo "deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
     echo "deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list)

# 配置 npm 国内镜像源（淘宝镜像）
# 使用 npmmirror.com（原淘宝镜像的新域名）
# 其他镜像配置（如 electron_mirror、sass_binary_site 等）需要通过环境变量设置
RUN npm config set registry https://registry.npmmirror.com

# 设置环境变量以加速特定包的下载（可选）
# 这些环境变量在安装相应包时会被使用
ENV ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/ \
    SASS_BINARY_SITE=https://npmmirror.com/mirrors/node-sass/ \
    PUPPETEER_DOWNLOAD_HOST=https://npmmirror.com/mirrors \
    CHROMEDRIVER_CDNURL=https://npmmirror.com/mirrors/chromedriver

# 安装基本工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    vim \
    sudo \
    curl \
    wget \
    git \
    jq \
    ca-certificates \
    iputils-ping \
    file \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 安装 Claude Code CLI 工具
RUN npm install -g @anthropic-ai/claude-code

# ============================================
# 浏览器相关依赖（可选）
# ============================================
# 通过构建参数 ENABLE_BROWSER_MCP 控制是否安装浏览器依赖
ARG ENABLE_BROWSER_MCP=false
RUN if [ "$ENABLE_BROWSER_MCP" = "true" ]; then \
    echo "安装浏览器相关依赖..." && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium \
    chromium-sandbox \
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    libxshmfence1 \
    && rm -rf /var/lib/apt/lists/* && \
    echo "安装 agent-browser CLI 工具..." && \
    npm install -g agent-browser && \
    echo "浏览器依赖安装完成"; \
    else \
    echo "跳过浏览器依赖安装（ENABLE_BROWSER_MCP=false）"; \
    fi

# 复制并设置入口脚本
COPY .devcontainer/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 设置入口点
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# 如果需要安装其他工具或依赖，可以在这里添加
# 例如：
# RUN npm install -g some-package

