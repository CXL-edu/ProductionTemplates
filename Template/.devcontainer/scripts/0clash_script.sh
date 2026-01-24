#!/bin/bash
# 使用与 docker-compose.yml 中挂载路径一致的目录
CLASH_DIR="$HOME/clash"
mkdir -p "$CLASH_DIR"; cd "$CLASH_DIR";

# 优先使用本地 assets 目录中的 clash-meta.gz 文件
# 注意：现在统一使用 mihomo 内核
if [ -f /workspace/assets/clash-meta.gz ]; then
    echo "使用本地 assets 目录中的 clash-meta.gz"
    cp /workspace/assets/clash-meta.gz clash-meta.gz
else
    echo "从网络下载 mihomo-linux-amd64-v1.18.1.gz"
    wget "https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz" -O clash-meta.gz || {
        echo "错误: 下载 mihomo 失败，请检查网络连接或使用本地 assets 文件"
        exit 1
    }
fi

# 确保在正确的目录下进行解压
cd "$CLASH_DIR"
# 如果 clash 可执行文件不存在，则解压
if [ ! -f clash ]; then
    gzip -d clash-meta.gz;
    # mihomo 解压后的文件名是 clash-meta
    if [ -f clash-meta ]; then
        mv clash-meta clash;
        chmod +x clash;
    else
        echo "错误: 解压后未找到 clash-meta 文件"
        exit 1
    fi
fi

# 确保在正确的目录下下载配置文件
cd "$CLASH_DIR"
# 从环境变量获取 Clash 配置 URL
if [ -z "$CLASH_CONFIG_URL" ] || [ "$CLASH_CONFIG_URL" = "YOUR_CLASH_CONFIG_URL_HERE" ]; then
    echo "错误: CLASH_CONFIG_URL 环境变量未设置或仍为占位符值"
    echo "请在 .env 文件中设置有效的 CLASH_CONFIG_URL"
    exit 1
fi
wget -O config.yaml "$CLASH_CONFIG_URL"

# 确保在正确的目录下复制 Country.mmdb
cd "$CLASH_DIR"
# 优先使用模板中的 Country.mmdb，如果不存在则尝试从 docker-volumes 复制
if [ -f /workspace/assets/Country.mmdb ]; then
    cp /workspace/assets/Country.mmdb "$CLASH_DIR/Country.mmdb"
    echo "使用模板中的 Country.mmdb"
elif [ -f /docker-volumes/0privates/Country.mmdb ]; then
    cp /docker-volumes/0privates/Country.mmdb "$CLASH_DIR/Country.mmdb"
    echo "使用 docker-volumes 中的 Country.mmdb"
else
    echo "警告: 未找到 Country.mmdb 文件"
fi

echo "export PATH=\"\$PATH:$CLASH_DIR\"" >> ~/.bashrc  
source ~/.bashrc 


# 为 clash 添加 DNS 和 TUN 配置
# 注意：需要将配置插入到原始配置文件的开头，而不是使用多个 YAML 文档
cat > /tmp/clash_extra_config.yaml << 'EOF'
dns:
  enable: true
  listen: 0.0.0.0:53
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - 8.8.8.8
    - 8.8.4.4
    - 223.5.5.5
    - 114.114.114.114
  fallback:
    - 8.8.8.8
    - 8.8.4.4
    - tls://dns.google
    - https://dns.google/dns-query
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4
tun:
  enable: true
  stack: system  # system 或 gvisor，system 模式更稳定
  inet4-address: 198.19.0.1/16  # 防止宿主机也开启tun代理时ip冲突
  dns-hijack:
    - 0.0.0.0:53
    - tcp://0.0.0.0:53
  auto-route: true
  auto-detect-interface: true
EOF

# 合并配置：将额外配置插入到原始配置文件的开头
# 使用 awk 在第一个非注释行之前插入配置
awk -v extra_config="$(cat /tmp/clash_extra_config.yaml)" '
BEGIN { inserted=0 }
/^[^#]/ && !inserted {
    print extra_config
    inserted=1
}
{ print }
' "$CLASH_DIR/config.yaml" > /tmp/clash_config_merged.yaml
mv /tmp/clash_config_merged.yaml "$CLASH_DIR/config.yaml"
rm /tmp/clash_extra_config.yaml

# 在后台启动 clash，输出重定向到日志文件
nohup "$CLASH_DIR/clash" -d . > "$CLASH_DIR/clash.log" 2>&1 &
echo "Clash 已在后台启动，PID: $!"
echo "日志文件: $CLASH_DIR/clash.log" 
