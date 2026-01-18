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
RUN npm config set registry https://registry.npmmirror.com && \
    npm config set disturl https://npmmirror.com/dist && \
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/ && \
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/ && \
    npm config set puppeteer_download_host https://npmmirror.com/mirrors && \
    npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver && \
    npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver && \
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs && \
    npm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium && \
    npm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector

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
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 安装 Claude Code CLI 工具
RUN npm install -g @anthropic-ai/claude-code

# 复制并设置入口脚本
COPY .devcontainer/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 设置入口点
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# 如果需要安装其他工具或依赖，可以在这里添加
# 例如：
# RUN npm install -g some-package

