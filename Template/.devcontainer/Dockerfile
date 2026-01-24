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
    # 进程管理工具
    procps \
    # 文件操作工具
    findutils \
    file \
    # 文本处理工具
    grep \
    sed \
    gawk \
    less \
    vim \
    # 网络工具
    curl \
    wget \
    net-tools \
    iproute2 \
    dnsutils \
    # 系统信息工具
    util-linux \
    fdisk \
    tree \
    # 压缩工具
    tar \
    gzip \
    zip \
    unzip \
    bzip2 \
    # 其他常用工具
    sudo \
    git \
    jq \
    ca-certificates \
    iputils-ping \
    # 系统监控与调试工具
    htop \
    strace \
    tcpdump \
    iotop \
    iftop \
    # 文件搜索工具
    mlocate \
    ripgrep \
    # 文本编辑器（轻量级替代）
    nano \
    # 文件比较工具
    diffutils \
    # 文件同步工具
    rsync \
    # 终端复用工具
    tmux \
    # 磁盘分析工具
    ncdu \
    # 其他压缩工具
    xz-utils \
    # 实用工具
    bc \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# 复制 assets 目录（优先使用本地 Miniforge 安装包）
RUN mkdir -p /tmp/assets
COPY assets /tmp/assets/

# ============================================
# 安装 Miniforge（轻量级 conda 发行版）
# ============================================
# 从构建参数读取版本，默认使用 25.11.0-1
ARG MINIFORGE_VERSION=25.11.0-1
ENV CONDA_DIR=/opt/conda \
    PATH=${PATH}:/opt/conda/bin

# 下载并安装 Miniforge（优先使用本地文件）
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        MINIFORGE_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        MINIFORGE_ARCH="aarch64"; \
    else \
        echo "不支持的架构: $ARCH" && exit 1; \
    fi && \
    MINIFORGE_FILENAME="Miniforge3-${MINIFORGE_VERSION}-Linux-${MINIFORGE_ARCH}.sh" && \
    MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/${MINIFORGE_FILENAME}" && \
    if [ -f "/tmp/assets/${MINIFORGE_FILENAME}" ]; then \
        echo "使用本地文件: /tmp/assets/${MINIFORGE_FILENAME}" && \
        cp "/tmp/assets/${MINIFORGE_FILENAME}" /tmp/miniforge.sh; \
    else \
        echo "本地文件不存在，从网络下载: ${MINIFORGE_URL}" && \
        wget --quiet --no-check-certificate "${MINIFORGE_URL}" -O /tmp/miniforge.sh || \
        (echo "下载失败，可手动下载 ${MINIFORGE_FILENAME} 到 assets 目录" && exit 1); \
    fi && \
    echo "开始安装 Miniforge..." && \
    /bin/bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    echo "安装完成，清理缓存..." && \
    rm /tmp/miniforge.sh && \
    ${CONDA_DIR}/bin/conda clean -afy

# 配置 conda 国内镜像源（清华大学镜像，加速下载）
RUN ${CONDA_DIR}/bin/conda config --system --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main && \
    ${CONDA_DIR}/bin/conda config --system --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free && \
    ${CONDA_DIR}/bin/conda config --system --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge && \
    ${CONDA_DIR}/bin/conda config --system --set show_channel_urls yes && \
    ${CONDA_DIR}/bin/conda config --system --set channel_priority strict

# 初始化 conda（自动激活 base 环境）
RUN ${CONDA_DIR}/bin/conda init bash && \
    echo "conda activate base" >> ~/.bashrc

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

