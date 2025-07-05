#!/bin/bash

# ======================================================================
# == VPS 自动化配置脚本 - 专业版 v1.0                              ==
# == 支持: Nginx反向代理、Web项目、X-UI VPN、SSL证书等            ==
# ======================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/vps_config.json"
LOG_FILE="$SCRIPT_DIR/vps_setup.log"
NGINX_CONF_DIR="/etc/nginx"
ACME_DIR="/root/.acme.sh"
XUI_PORT="54321"

# 日志函数
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
  echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
  exit 1
}

info() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# 检查是否为root用户
check_root() {
  if [[ $EUID -ne 0 ]]; then
    error "此脚本需要root权限运行，请使用 sudo 执行"
  fi
}

# 检查系统兼容性
check_system() {
  log "检查系统兼容性..."

  # 检测操作系统
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
  else
    error "无法检测操作系统"
  fi

  # 检测架构
  ARCH=$(uname -m)

  log "操作系统: $OS $VER"
  log "架构: $ARCH"

  # 支持的发行版
  case $ID in
  ubuntu | debian | centos | rhel | almalinux | rocky)
    log "系统兼容性检查通过"
    ;;
  *)
    warn "未测试的操作系统: $OS，可能存在问题"
    ;;
  esac
}

# 更新系统
update_system() {
  log "更新系统包..."

  case $ID in
  ubuntu | debian)
    apt update -y
    apt upgrade -y
    apt install -y curl wget git unzip software-properties-common
    ;;
  centos | rhel | almalinux | rocky)
    yum update -y
    yum install -y curl wget git unzip epel-release
    ;;
  esac
}

# 安装Nginx
install_nginx() {
  log "安装Nginx..."

  case $ID in
  ubuntu | debian)
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    ;;
  centos | rhel | almalinux | rocky)
    yum install -y nginx
    systemctl enable nginx
    systemctl start nginx
    ;;
  esac

  # 创建高性能nginx配置
  create_nginx_config
}

# 创建高性能Nginx配置
create_nginx_config() {
  log "创建高性能Nginx配置..."

  # 获取系统信息用于优化
  CPU_CORES=$(nproc)
  MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  MEMORY_MB=$((MEMORY_KB / 1024))

  # 计算worker进程数
  WORKER_PROCESSES=$CPU_CORES
  WORKER_CONNECTIONS=$((MEMORY_MB * 1024 / CPU_CORES / 4))

  # 限制最大连接数
  if [[ $WORKER_CONNECTIONS -gt 8192 ]]; then
    WORKER_CONNECTIONS=8192
  fi

  # 创建主配置文件
  cat >/etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes $WORKER_PROCESSES;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;

error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    use epoll;
    worker_connections $WORKER_CONNECTIONS;
    multi_accept on;
    accept_mutex off;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    # 基础优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # 隐藏版本号
    server_tokens off;
    
    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

  # 创建默认站点配置
  mkdir -p /etc/nginx/sites-available
  mkdir -p /etc/nginx/sites-enabled

  cat >/etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    root /var/www/html;
    index index.html index.htm index.php;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
    
    # PHP支持（如果需要）
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
EOF

  # 启用默认站点
  ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

  # 测试配置
  nginx -t
  systemctl reload nginx

  log "Nginx高性能配置完成"
}

# 安装acme.sh
install_acme() {
  log "安装acme.sh..."

  if [[ ! -d "$ACME_DIR" ]]; then
    curl https://get.acme.sh | sh -s email=admin@example.com
    source ~/.bashrc
  else
    log "acme.sh已安装，更新中..."
    "$ACME_DIR"/acme.sh --upgrade
  fi

  # 设置自动更新
  "$ACME_DIR"/acme.sh --upgrade --auto-upgrade

  log "acme.sh安装完成"
}

# 安装X-UI
install_xui() {
  log "安装X-UI..."

  # 使用yonggekkk的x-ui-yg脚本
  bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/install.sh)

  log "X-UI安装完成"
}

# 检查SSL证书申请前置条件
check_ssl_prerequisites() {
  local domain="$1"
  log "检查SSL证书申请前置条件..."

  # 1. 检查域名格式
  if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    error "域名格式不正确: $domain"
  fi

  # 2. 检查域名解析
  log "检查域名DNS解析..."
  local resolved_ip=""
  if command -v dig >/dev/null 2>&1; then
    resolved_ip=$(dig +short "$domain" | head -1)
  elif command -v nslookup >/dev/null 2>&1; then
    resolved_ip=$(nslookup "$domain" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}')
  else
    warn "未找到dig或nslookup命令，无法检查DNS解析"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi

  if [[ -n "$resolved_ip" ]]; then
    log "域名 $domain 解析到: $resolved_ip"

    # 获取服务器公网IP
    local server_ip=""
    if command -v curl >/dev/null 2>&1; then
      server_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || curl -s --max-time 10 ipinfo.io/ip 2>/dev/null)
    fi

    if [[ -n "$server_ip" && "$resolved_ip" != "$server_ip" ]]; then
      warn "域名 $domain 解析的IP ($resolved_ip) 与服务器IP ($server_ip) 不匹配"
      read -p "是否继续? (y/N): " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
      fi
    fi
  else
    error "无法解析域名 $domain，请检查DNS配置"
  fi

  # 3. 检查80端口是否可用
  log "检查80端口可用性..."
  if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    local port80_process=$(netstat -tlnp 2>/dev/null | grep ":80 " | awk '{print $7}' | cut -d'/' -f2)
    if [[ "$port80_process" != "nginx" ]]; then
      error "80端口被 $port80_process 占用，acme.sh需要80端口进行域名验证"
    else
      log "80端口被nginx占用，申请证书时会临时停止nginx"
    fi
  else
    log "80端口可用"
  fi

  # 4. 检查443端口是否可用
  log "检查443端口可用性..."
  if netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    local port443_process=$(netstat -tlnp 2>/dev/null | grep ":443 " | awk '{print $7}' | cut -d'/' -f2)
    warn "443端口被 $port443_process 占用，这可能会影响HTTPS访问"
  else
    log "443端口可用"
  fi

  # 5. 检查防火墙设置
  log "检查防火墙设置..."
  case $ID in
  ubuntu | debian)
    if command -v ufw >/dev/null 2>&1; then
      if ufw status | grep -q "Status: active"; then
        if ! ufw status | grep -q "80/tcp.*ALLOW"; then
          warn "防火墙可能阻止80端口，这会影响证书申请"
          read -p "是否继续? (y/N): " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
          fi
        fi
      fi
    fi
    ;;
  centos | rhel | almalinux | rocky)
    if command -v firewall-cmd >/dev/null 2>&1; then
      if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        if ! firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp"; then
          warn "防火墙可能阻止80端口，这会影响证书申请"
          read -p "是否继续? (y/N): " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
          fi
        fi
      fi
    fi
    ;;
  esac

  # 6. 检查网络连接
  log "检查网络连接..."
  if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    error "无法连接到外网，acme.sh需要网络连接来验证域名"
  fi

  # 7. 检查Let's Encrypt服务器连接
  log "检查Let's Encrypt服务器连接..."
  if ! curl -s --max-time 10 https://acme-v02.api.letsencrypt.org/directory >/dev/null 2>&1; then
    error "无法连接到Let's Encrypt服务器，请检查网络连接"
  fi

  # 8. 检查acme.sh安装
  if [[ ! -d "$ACME_DIR" ]]; then
    error "acme.sh未安装，请先运行脚本安装acme.sh"
  fi

  # 9. 检查必要工具
  log "检查必要工具..."
  local missing_tools=()

  for tool in openssl curl socat; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    warn "缺少必要工具: ${missing_tools[*]}"
    log "正在安装缺失的工具..."

    case $ID in
    ubuntu | debian)
      apt install -y "${missing_tools[@]}"
      ;;
    centos | rhel | almalinux | rocky)
      yum install -y "${missing_tools[@]}"
      ;;
    esac
  fi

  # 10. 检查磁盘空间
  log "检查磁盘空间..."
  local available_space=$(df /etc/nginx/ssl 2>/dev/null | tail -1 | awk '{print $4}')
  if [[ -n "$available_space" && $available_space -lt 10240 ]]; then
    warn "磁盘空间不足（小于10MB），可能影响证书存储"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi

  # 11. 检查证书是否已存在
  if [[ -f "/etc/nginx/ssl/${domain}.crt" ]]; then
    local cert_expiry=$(openssl x509 -in "/etc/nginx/ssl/${domain}.crt" -noout -enddate 2>/dev/null | cut -d= -f2)
    if [[ -n "$cert_expiry" ]]; then
      local expiry_timestamp=$(date -d "$cert_expiry" +%s 2>/dev/null)
      local current_timestamp=$(date +%s)
      local days_until_expiry=$(((expiry_timestamp - current_timestamp) / 86400))

      if [[ $days_until_expiry -gt 30 ]]; then
        warn "域名 $domain 的SSL证书已存在且有效期还有 $days_until_expiry 天"
        read -p "是否重新申请证书? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log "跳过证书申请"
          return 0
        fi
      else
        log "证书即将过期，将重新申请"
      fi
    fi
  fi

  # 12. 检查域名是否可访问
  log "检查域名可访问性..."
  if command -v curl >/dev/null 2>&1; then
    local http_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$domain" 2>/dev/null)
    if [[ "$http_response" == "000" ]]; then
      warn "域名 $domain 无法通过HTTP访问，这可能会影响证书申请"
      read -p "是否继续? (y/N): " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
      fi
    else
      log "域名 $domain 可以正常访问 (HTTP状态码: $http_response)"
    fi
  fi

  log "SSL证书申请前置条件检查完成"
  return 0
}

# 交互式配置域名
configure_domain() {
  echo -e "${CYAN}=== 域名配置 ===${NC}"

  read -p "请输入主域名 (例如: example.com): " DOMAIN
  if [[ -z "$DOMAIN" ]]; then
    warn "未输入域名，跳过域名配置"
    return
  fi

  # 检查SSL证书申请前置条件
  if ! check_ssl_prerequisites "$DOMAIN"; then
    return
  fi

  # 创建SSL配置目录
  mkdir -p /etc/nginx/ssl

  # 申请SSL证书
  log "申请SSL证书..."
  "$ACME_DIR"/acme.sh --issue -d "$DOMAIN" --standalone --keylength 2048

  # 安装证书
  "$ACME_DIR"/acme.sh --installcert -d "$DOMAIN" \
    --key-file /etc/nginx/ssl/"$DOMAIN".key \
    --fullchain-file /etc/nginx/ssl/"$DOMAIN".crt \
    --reloadcmd "systemctl reload nginx"

  # 配置自动续期
  setup_ssl_auto_renewal

  log "域名 $DOMAIN 配置完成"
}

# 设置SSL证书自动续期
setup_ssl_auto_renewal() {
  log "配置SSL证书自动续期..."

  # 创建续期脚本
  cat >/usr/local/bin/ssl-renew.sh <<'EOF'
#!/bin/bash

# SSL证书自动续期脚本
LOG_FILE="/var/log/ssl-renew.log"
ACME_DIR="/root/.acme.sh"

# 日志函数
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查证书是否需要续期
check_and_renew() {
  local domain="$1"
  
  # 检查证书是否存在
  if [[ ! -f "/etc/nginx/ssl/${domain}.crt" ]]; then
    log "证书文件不存在: ${domain}.crt"
    return 1
  fi
  
  # 获取证书过期时间
  local expiry_date=$(openssl x509 -in "/etc/nginx/ssl/${domain}.crt" -noout -enddate | cut -d= -f2)
  local expiry_timestamp=$(date -d "$expiry_date" +%s)
  local current_timestamp=$(date +%s)
  local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
  
  log "域名 ${domain} 证书将在 ${days_until_expiry} 天后过期"
  
  # 如果证书在30天内过期，则续期
  if [[ $days_until_expiry -le 30 ]]; then
    log "开始续期域名 ${domain} 的SSL证书..."
    
    # 停止nginx以释放80端口
    systemctl stop nginx
    
    # 续期证书
    if "$ACME_DIR"/acme.sh --renew -d "$domain" --standalone; then
      log "域名 ${domain} 证书续期成功"
      
      # 重新安装证书
      "$ACME_DIR"/acme.sh --installcert -d "$domain" \
        --key-file "/etc/nginx/ssl/${domain}.key" \
        --fullchain-file "/etc/nginx/ssl/${domain}.crt" \
        --reloadcmd "systemctl reload nginx"
      
      # 启动nginx
      systemctl start nginx
      
      # 发送通知（如果有配置）
      send_notification "SSL证书续期成功" "域名 ${domain} 的SSL证书已成功续期"
      
      return 0
    else
      log "域名 ${domain} 证书续期失败"
      
      # 启动nginx
      systemctl start nginx
      
      # 发送通知（如果有配置）
      send_notification "SSL证书续期失败" "域名 ${domain} 的SSL证书续期失败，请手动检查"
      
      return 1
    fi
  else
    log "域名 ${domain} 证书无需续期"
    return 0
  fi
}

# 发送通知（可扩展）
send_notification() {
  local title="$1"
  local message="$2"
  
  # 这里可以添加各种通知方式
  # 例如：邮件、钉钉、企业微信、Telegram等
  
  # 示例：记录到系统日志
  logger -t "SSL-Renewal" "$title: $message"
  
  # 示例：如果配置了邮件通知
  # if [[ -n "$MAIL_TO" ]]; then
  #   echo "$message" | mail -s "$title" "$MAIL_TO"
  # fi
}

# 主函数
main() {
  log "开始SSL证书自动续期检查..."
  
  # 检查主域名
  if [[ -n "$DOMAIN" ]]; then
    check_and_renew "$DOMAIN"
  fi
  
  # 检查子域名（从nginx配置中提取）
  for config_file in /etc/nginx/sites-enabled/*; do
    if [[ -f "$config_file" ]]; then
      # 提取server_name中的域名
      domains=$(grep -h "server_name" "$config_file" | sed 's/server_name//g' | tr -d ';' | tr ' ' '\n' | grep -v '^$' | grep -v '_')
      
      for domain in $domains; do
        if [[ "$domain" != "$DOMAIN" ]] && [[ -f "/etc/nginx/ssl/${domain}.crt" ]]; then
          check_and_renew "$domain"
        fi
      done
    fi
  done
  
  log "SSL证书自动续期检查完成"
}

# 执行主函数
main "$@"
EOF

  chmod +x /usr/local/bin/ssl-renew.sh

  # 创建cron任务（每天凌晨2点检查）
  (
    crontab -l 2>/dev/null
    echo "0 2 * * * /usr/local/bin/ssl-renew.sh"
  ) | crontab -

  # 创建证书状态检查脚本
  cat >/usr/local/bin/ssl-status.sh <<'EOF'
#!/bin/bash

# SSL证书状态检查脚本
echo "=== SSL证书状态检查 ==="
echo

for cert_file in /etc/nginx/ssl/*.crt; do
  if [[ -f "$cert_file" ]]; then
    domain=$(basename "$cert_file" .crt)
    expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    expiry_timestamp=$(date -d "$expiry_date" +%s)
    current_timestamp=$(date +%s)
    days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    if [[ $days_until_expiry -le 30 ]]; then
      echo -e "\033[31m⚠️  域名: $domain\033[0m"
      echo -e "   过期时间: $expiry_date"
      echo -e "   剩余天数: $days_until_expiry 天"
    elif [[ $days_until_expiry -le 60 ]]; then
      echo -e "\033[33m⚠️  域名: $domain\033[0m"
      echo -e "   过期时间: $expiry_date"
      echo -e "   剩余天数: $days_until_expiry 天"
    else
      echo -e "\033[32m✅ 域名: $domain\033[0m"
      echo -e "   过期时间: $expiry_date"
      echo -e "   剩余天数: $days_until_expiry 天"
    fi
    echo
  fi
done

echo "自动续期任务状态:"
if crontab -l 2>/dev/null | grep -q "ssl-renew.sh"; then
  echo -e "\033[32m✅ 自动续期已启用\033[0m"
  echo "执行时间: 每天凌晨2点"
else
  echo -e "\033[31m❌ 自动续期未启用\033[0m"
fi
EOF

  chmod +x /usr/local/bin/ssl-status.sh

  log "SSL证书自动续期配置完成"
  log "续期脚本: /usr/local/bin/ssl-renew.sh"
  log "状态检查: /usr/local/bin/ssl-status.sh"
  log "自动续期时间: 每天凌晨2点"
}

# 交互式配置反向代理
configure_proxy() {
  echo -e "${CYAN}=== 反向代理配置 ===${NC}"

  PROXY_CONFIGS=()
  PATH_PROXY_CONFIGS=()

  while true; do
    echo
    echo "请选择代理类型:"
    echo "1. 子域名代理 (例如: api.example.com -> 127.0.0.1:3000)"
    echo "2. 路径代理 (例如: example.com/api -> 127.0.0.1:3000)"
    echo "3. 完成配置"
    read -p "请选择 (1-3): " proxy_type

    case $proxy_type in
    1)
      configure_subdomain_proxy
      ;;
    2)
      configure_path_proxy
      ;;
    3)
      break
      ;;
    *)
      echo -e "${RED}无效选择，请重新输入${NC}"
      ;;
    esac
  done

  # 应用代理配置
  if [[ ${#PROXY_CONFIGS[@]} -gt 0 ]] || [[ ${#PATH_PROXY_CONFIGS[@]} -gt 0 ]]; then
    apply_proxy_configs
  fi
}

# 配置子域名代理
configure_subdomain_proxy() {
  echo -e "${CYAN}--- 子域名代理配置 ---${NC}"

  while true; do
    echo
    read -p "是否添加子域名代理配置? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      break
    fi

    # 获取代理配置信息
    read -p "请输入子域名 (例如: api): " SUBDOMAIN
    if [[ -z "$SUBDOMAIN" ]]; then
      warn "子域名不能为空"
      continue
    fi

    read -p "请输入后端服务地址 (例如: 127.0.0.1:8080): " BACKEND
    if [[ -z "$BACKEND" ]]; then
      warn "后端地址不能为空"
      continue
    fi

    read -p "是否启用SSL? (Y/n): " -n 1 -r
    echo
    USE_SSL=$([[ $REPLY =~ ^[Nn]$ ]] && echo "false" || echo "true")

    read -p "是否支持WebSocket? (Y/n): " -n 1 -r
    echo
    WEBSOCKET=$([[ $REPLY =~ ^[Nn]$ ]] && echo "false" || echo "true")

    # 保存配置
    PROXY_CONFIGS+=("$SUBDOMAIN:$BACKEND:$USE_SSL:$WEBSOCKET")

    echo -e "${GREEN}子域名代理配置已添加: $SUBDOMAIN.$DOMAIN -> $BACKEND${NC}"
  done
}

# 配置路径代理
configure_path_proxy() {
  echo -e "${CYAN}--- 路径代理配置 ---${NC}"

  while true; do
    echo
    read -p "是否添加路径代理配置? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      break
    fi

    # 获取代理配置信息
    read -p "请输入路径 (例如: /api): " PATH_PREFIX
    if [[ -z "$PATH_PREFIX" ]]; then
      warn "路径不能为空"
      continue
    fi

    # 确保路径以/开头
    if [[ ! "$PATH_PREFIX" =~ ^/ ]]; then
      PATH_PREFIX="/$PATH_PREFIX"
    fi

    read -p "请输入后端服务地址 (例如: 127.0.0.1:8080): " BACKEND
    if [[ -z "$BACKEND" ]]; then
      warn "后端地址不能为空"
      continue
    fi

    read -p "是否支持WebSocket? (Y/n): " -n 1 -r
    echo
    WEBSOCKET=$([[ $REPLY =~ ^[Nn]$ ]] && echo "false" || echo "true")

    read -p "是否移除路径前缀? (y/N): " -n 1 -r
    echo
    REMOVE_PREFIX=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")

    # 保存配置
    PATH_PROXY_CONFIGS+=("$PATH_PREFIX:$BACKEND:$WEBSOCKET:$REMOVE_PREFIX")

    echo -e "${GREEN}路径代理配置已添加: $DOMAIN$PATH_PREFIX -> $BACKEND${NC}"
  done
}

# 应用代理配置
apply_proxy_configs() {
  log "应用反向代理配置..."

  # 处理子域名代理配置
  for config in "${PROXY_CONFIGS[@]}"; do
    IFS=':' read -r subdomain backend use_ssl websocket <<<"$config"

    # 创建代理配置文件
    cat >"/etc/nginx/sites-available/$subdomain" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $subdomain.$DOMAIN;
    
    # 重定向到HTTPS
    if (\$use_ssl = "true") {
        return 301 https://\$server_name\$request_uri;
    }
    
    location / {
        proxy_pass http://$backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

    # 如果启用SSL，创建HTTPS配置
    if [[ "$use_ssl" == "true" ]]; then
      cat >>"/etc/nginx/sites-available/$subdomain" <<EOF

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $subdomain.$DOMAIN;
    
    ssl_certificate /etc/nginx/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;
    
    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        proxy_pass http://$backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    fi

    # 启用站点
    ln -sf "/etc/nginx/sites-available/$subdomain" "/etc/nginx/sites-enabled/"

    log "子域名代理配置 $subdomain.$DOMAIN -> $backend 已创建"
  done

  # 处理路径代理配置
  if [[ ${#PATH_PROXY_CONFIGS[@]} -gt 0 ]]; then
    create_path_proxy_config
  fi

  # 重新加载nginx
  nginx -t && systemctl reload nginx
  log "所有代理配置已应用"
}

# 创建路径代理配置
create_path_proxy_config() {
  log "创建路径代理配置..."

  # 创建主域名的路径代理配置
  cat >"/etc/nginx/sites-available/path-proxy" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    
    # 路径代理配置
EOF

  # 添加路径代理规则
  for config in "${PATH_PROXY_CONFIGS[@]}"; do
    IFS=':' read -r path_prefix backend websocket remove_prefix <<<"$config"

    # 处理路径前缀移除
    if [[ "$remove_prefix" == "true" ]]; then
      proxy_pass="http://$backend"
    else
      proxy_pass="http://$backend$path_prefix"
    fi

    cat >>"/etc/nginx/sites-available/path-proxy" <<EOF

    location $path_prefix {
        proxy_pass $proxy_pass;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
EOF

    log "路径代理配置 $DOMAIN$path_prefix -> $backend 已添加"
  done

  # 添加默认站点配置
  cat >>"/etc/nginx/sites-available/path-proxy" <<EOF

    # 默认站点
    location / {
        root /var/www/html;
        index index.html index.htm index.php;
        try_files \$uri \$uri/ =404;
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
EOF

  # 如果启用了SSL，创建HTTPS配置
  if [[ -n "$DOMAIN" ]]; then
    cat >>"/etc/nginx/sites-available/path-proxy" <<EOF

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;
    
    ssl_certificate /etc/nginx/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;
    
    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # 路径代理配置
EOF

    # 添加HTTPS路径代理规则
    for config in "${PATH_PROXY_CONFIGS[@]}"; do
      IFS=':' read -r path_prefix backend websocket remove_prefix <<<"$config"

      # 处理路径前缀移除
      if [[ "$remove_prefix" == "true" ]]; then
        proxy_pass="http://$backend"
      else
        proxy_pass="http://$backend$path_prefix"
      fi

      cat >>"/etc/nginx/sites-available/path-proxy" <<EOF

    location $path_prefix {
        proxy_pass $proxy_pass;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
EOF
    done

    # 添加HTTPS默认站点配置
    cat >>"/etc/nginx/sites-available/path-proxy" <<EOF

    # 默认站点
    location / {
        root /var/www/html;
        index index.html index.htm index.php;
        try_files \$uri \$uri/ =404;
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
EOF
  fi

  # 启用路径代理配置
  ln -sf "/etc/nginx/sites-available/path-proxy" "/etc/nginx/sites-enabled/"

  log "路径代理配置完成"
}

# 配置防火墙
configure_firewall() {
  log "配置防火墙..."

  case $ID in
  ubuntu | debian)
    # 安装ufw
    apt install -y ufw

    # 默认策略
    ufw default deny incoming
    ufw default allow outgoing

    # 允许SSH
    ufw allow ssh

    # 允许HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # 允许X-UI端口
    ufw allow $XUI_PORT/tcp

    # 启用防火墙
    ufw --force enable
    ;;
  centos | rhel | almalinux | rocky)
    # 使用firewalld
    systemctl enable firewalld
    systemctl start firewalld

    # 允许服务
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-port=$XUI_PORT/tcp

    # 重新加载
    firewall-cmd --reload
    ;;
  esac

  log "防火墙配置完成"
}

# 系统优化
optimize_system() {
  log "系统优化..."

  # 创建系统优化配置
  cat >/etc/sysctl.d/99-vps-optimization.conf <<EOF
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535

# 文件描述符限制
fs.file-max = 65535

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

  # 应用配置
  sysctl -p /etc/sysctl.d/99-vps-optimization.conf

  # 设置文件描述符限制
  cat >>/etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

  log "系统优化完成"
}

# 创建管理脚本
create_management_script() {
  log "创建管理脚本..."

  cat >/usr/local/bin/vps-manager <<'EOF'
#!/bin/bash

# VPS管理脚本
SCRIPT_DIR="/root/vps-init"

case "$1" in
    "status")
        echo "=== 服务状态 ==="
        systemctl status nginx --no-pager -l
        echo
        systemctl status x-ui --no-pager -l
        ;;
    "restart")
        echo "重启服务..."
        systemctl restart nginx
        systemctl restart x-ui
        ;;
    "logs")
        echo "=== Nginx日志 ==="
        tail -f /var/log/nginx/access.log
        ;;
    "ssl-renew")
        echo "更新SSL证书..."
        /root/.acme.sh/acme.sh --renew-all
        ;;
    "ssl-status")
        echo "检查SSL证书状态..."
        /usr/local/bin/ssl-status.sh
        ;;
    "ssl-check")
        echo "检查SSL证书申请前置条件..."
        /root/vps-init/ssl-check.sh
        ;;
    "backup")
        echo "备份配置..."
        tar -czf /root/backup-$(date +%Y%m%d).tar.gz \
            /etc/nginx \
            /usr/local/x-ui \
            /root/.acme.sh
        echo "备份完成: /root/backup-$(date +%Y%m%d).tar.gz"
        ;;
    "proxy")
        echo "启动代理管理工具..."
        /root/vps-init/proxy-manager.sh
        ;;
    *)
        echo "用法: $0 {status|restart|logs|ssl-renew|ssl-status|ssl-check|backup|proxy}"
        echo ""
        echo "命令说明:"
        echo "  status     - 查看服务状态"
        echo "  restart    - 重启服务"
        echo "  logs       - 查看日志"
        echo "  ssl-renew  - 更新SSL证书"
        echo "  ssl-status - 检查SSL证书状态"
        echo "  ssl-check  - 检查SSL证书申请前置条件"
        echo "  backup     - 备份配置"
        echo "  proxy      - 代理管理工具"
        exit 1
        ;;
esac
EOF

  chmod +x /usr/local/bin/vps-manager
  log "管理脚本创建完成，使用: vps-manager {status|restart|logs|ssl-renew|backup|proxy}"

  # 复制代理管理脚本到系统目录
  cp "$SCRIPT_DIR/proxy-manager.sh" /usr/local/bin/proxy-manager
  chmod +x /usr/local/bin/proxy-manager
  log "代理管理工具已安装，使用: proxy-manager 或 vps-manager proxy"
}

# 显示安装信息
show_installation_info() {
  echo -e "${GREEN}"
  echo "=========================================="
  echo "           VPS配置完成！"
  echo "=========================================="
  echo -e "${NC}"

  echo -e "${CYAN}服务信息:${NC}"
  echo "Nginx: http://$(curl -s ifconfig.me)"
  echo "X-UI面板: http://$(curl -s ifconfig.me):$XUI_PORT"

  if [[ -n "$DOMAIN" ]]; then
    echo "主域名: $DOMAIN"
    echo "HTTPS: https://$DOMAIN"
  fi

  echo
  echo -e "${CYAN}管理命令:${NC}"
  echo "vps-manager status     - 查看服务状态"
  echo "vps-manager restart    - 重启服务"
  echo "vps-manager logs       - 查看日志"
  echo "vps-manager ssl-renew  - 更新SSL证书"
  echo "vps-manager ssl-status - 检查SSL证书状态"
  echo "vps-manager ssl-check  - 检查SSL证书申请前置条件"
  echo "vps-manager backup     - 备份配置"
  echo "vps-manager proxy      - 代理管理工具"
  echo "proxy-manager         - 直接启动代理管理工具"

  echo
  echo -e "${YELLOW}重要提醒:${NC}"
  echo "1. 请及时修改X-UI面板的默认密码"
  echo "2. 定期备份配置文件"
  echo "3. 监控系统资源使用情况"
  echo "4. 定期更新系统和软件包"

  echo
  echo -e "${GREEN}安装日志: $LOG_FILE${NC}"
}

# 主函数
main() {
  echo -e "${PURPLE}"
  echo "=========================================="
  echo "        VPS自动化配置脚本"
  echo "=========================================="
  echo -e "${NC}"

  # 检查权限
  check_root

  # 检查系统
  check_system

  # 更新系统
  update_system

  # 安装基础服务
  install_nginx
  install_acme
  install_xui

  # 交互式配置
  configure_domain
  configure_proxy

  # 系统配置
  configure_firewall
  optimize_system

  # 创建管理工具
  create_management_script

  # 显示完成信息
  show_installation_info
}

# 执行主函数
main "$@"
