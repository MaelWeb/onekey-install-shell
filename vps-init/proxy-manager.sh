#!/bin/bash

# ======================================================================
# == VPS 代理管理脚本                                              ==
# == 支持后续添加、删除和管理代理配置                                ==
# ======================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/vps_config.json"
NGINX_CONF_DIR="/etc/nginx"
DOMAIN=""

# 日志函数
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
  echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
  exit 1
}

# 检查是否为root用户
check_root() {
  if [[ $EUID -ne 0 ]]; then
    error "此脚本需要root权限运行，请使用 sudo 执行"
  fi
}

# 加载现有配置
load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    DOMAIN=$(jq -r '.domain.main_domain // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    log "加载现有配置: 域名 = $DOMAIN"
  else
    warn "未找到配置文件，请先运行主安装脚本"
    read -p "请输入主域名: " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
      error "域名不能为空"
    fi
  fi
}

# 显示主菜单
show_menu() {
  echo -e "${PURPLE}"
  echo "=========================================="
  echo "            VPS 代理管理工具"
  echo "=========================================="
  echo -e "${NC}"
  echo "当前域名: ${CYAN}$DOMAIN${NC}"
  echo
  echo "请选择操作:"
  echo "1. 添加子域名代理"
  echo "2. 添加路径代理"
  echo "3. 查看现有代理配置"
  echo "4. 删除代理配置"
  echo "5. 重新生成所有代理配置"
  echo "6. 测试代理配置"
  echo "7. 备份代理配置"
  echo "8. 恢复代理配置"
  echo "9. 退出"
  echo
}

# 添加子域名代理
add_subdomain_proxy() {
  echo -e "${CYAN}=== 添加子域名代理 ===${NC}"

  while true; do
    echo
    read -p "请输入子域名 (例如: api): " SUBDOMAIN
    if [[ -z "$SUBDOMAIN" ]]; then
      warn "子域名不能为空"
      continue
    fi

    # 检查是否已存在
    if [[ -f "/etc/nginx/sites-available/$SUBDOMAIN" ]]; then
      warn "子域名 $SUBDOMAIN 已存在"
      read -p "是否覆盖? (y/N): " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        continue
      fi
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

    # 创建代理配置
    create_subdomain_config "$SUBDOMAIN" "$BACKEND" "$USE_SSL" "$WEBSOCKET"

    read -p "是否继续添加? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      break
    fi
  done
}

# 添加路径代理
add_path_proxy() {
  echo -e "${CYAN}=== 添加路径代理 ===${NC}"

  while true; do
    echo
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

    # 添加到路径代理配置
    add_path_to_config "$PATH_PREFIX" "$BACKEND" "$WEBSOCKET" "$REMOVE_PREFIX"

    read -p "是否继续添加? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      break
    fi
  done
}

# 创建子域名配置
create_subdomain_config() {
  local subdomain=$1
  local backend=$2
  local use_ssl=$3
  local websocket=$4

  log "创建子域名代理配置: $subdomain.$DOMAIN -> $backend"

  # 创建HTTP配置
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

  # 测试并重载配置
  nginx -t && systemctl reload nginx

  log "子域名代理配置完成: $subdomain.$DOMAIN -> $backend"
}

# 添加路径到配置
add_path_to_config() {
  local path_prefix=$1
  local backend=$2
  local websocket=$3
  local remove_prefix=$4

  log "添加路径代理: $DOMAIN$path_prefix -> $backend"

  # 检查是否存在路径代理配置
  if [[ ! -f "/etc/nginx/sites-available/path-proxy" ]]; then
    create_new_path_proxy_config
  fi

  # 处理路径前缀移除
  if [[ "$remove_prefix" == "true" ]]; then
    proxy_pass="http://$backend"
  else
    proxy_pass="http://$backend$path_prefix"
  fi

  # 在HTTPS配置之前插入新的路径配置
  local temp_file=$(mktemp)
  local inserted=false

  while IFS= read -r line; do
    echo "$line" >>"$temp_file"

    # 在第一个location块之前插入新配置
    if [[ "$line" =~ ^[[:space:]]*location[[:space:]]+/ ]] && [[ "$inserted" == "false" ]]; then
      cat >>"$temp_file" <<EOF

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
      inserted=true
    fi
  done <"/etc/nginx/sites-available/path-proxy"

  # 替换原文件
  mv "$temp_file" "/etc/nginx/sites-available/path-proxy"

  # 测试并重载配置
  nginx -t && systemctl reload nginx

  log "路径代理配置完成: $DOMAIN$path_prefix -> $backend"
}

# 创建新的路径代理配置
create_new_path_proxy_config() {
  log "创建新的路径代理配置文件"

  cat >"/etc/nginx/sites-available/path-proxy" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    
    # 路径代理配置
    
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
  if [[ -n "$DOMAIN" ]] && [[ -f "/etc/nginx/ssl/$DOMAIN.crt" ]]; then
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

  # 启用配置
  ln -sf "/etc/nginx/sites-available/path-proxy" "/etc/nginx/sites-enabled/"
}

# 查看现有代理配置
show_proxy_configs() {
  echo -e "${CYAN}=== 现有代理配置 ===${NC}"
  echo

  echo -e "${YELLOW}子域名代理:${NC}"
  for config in /etc/nginx/sites-enabled/*; do
    if [[ -L "$config" ]] && [[ "$(basename "$config")" != "default" ]] && [[ "$(basename "$config")" != "path-proxy" ]]; then
      local subdomain=$(basename "$config")
      echo "  - $subdomain.$DOMAIN"
    fi
  done

  echo
  echo -e "${YELLOW}路径代理:${NC}"
  if [[ -f "/etc/nginx/sites-available/path-proxy" ]]; then
    grep -E "^[[:space:]]*location[[:space:]]+/" /etc/nginx/sites-available/path-proxy | while read -r line; do
      local path=$(echo "$line" | sed 's/^[[:space:]]*location[[:space:]]*//' | sed 's/[[:space:]]*{.*$//')
      echo "  - $DOMAIN$path"
    done
  fi

  echo
  echo -e "${YELLOW}启用的站点:${NC}"
  ls -la /etc/nginx/sites-enabled/
}

# 删除代理配置
delete_proxy_config() {
  echo -e "${CYAN}=== 删除代理配置 ===${NC}"
  echo
  echo "请选择要删除的配置类型:"
  echo "1. 删除子域名代理"
  echo "2. 删除路径代理"
  echo "3. 返回主菜单"

  read -p "请选择 (1-3): " choice

  case $choice in
  1)
    delete_subdomain_proxy
    ;;
  2)
    delete_path_proxy
    ;;
  3)
    return
    ;;
  *)
    echo -e "${RED}无效选择${NC}"
    ;;
  esac
}

# 删除子域名代理
delete_subdomain_proxy() {
  echo -e "${YELLOW}现有子域名代理:${NC}"
  local count=0
  local subdomains=()

  for config in /etc/nginx/sites-enabled/*; do
    if [[ -L "$config" ]] && [[ "$(basename "$config")" != "default" ]] && [[ "$(basename "$config")" != "path-proxy" ]]; then
      local subdomain=$(basename "$config")
      subdomains+=("$subdomain")
      echo "$((++count)). $subdomain.$DOMAIN"
    fi
  done

  if [[ $count -eq 0 ]]; then
    echo "没有找到子域名代理配置"
    return
  fi

  read -p "请选择要删除的配置 (1-$count): " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
    local subdomain=${subdomains[$((choice - 1))]}

    read -p "确认删除 $subdomain.$DOMAIN 的代理配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # 删除配置
      rm -f "/etc/nginx/sites-enabled/$subdomain"
      rm -f "/etc/nginx/sites-available/$subdomain"

      # 重载nginx
      nginx -t && systemctl reload nginx

      log "已删除子域名代理配置: $subdomain.$DOMAIN"
    fi
  else
    echo -e "${RED}无效选择${NC}"
  fi
}

# 删除路径代理
delete_path_proxy() {
  if [[ ! -f "/etc/nginx/sites-available/path-proxy" ]]; then
    echo "没有找到路径代理配置"
    return
  fi

  echo -e "${YELLOW}现有路径代理:${NC}"
  local count=0
  local paths=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*location[[:space:]]+/ ]]; then
      local path=$(echo "$line" | sed 's/^[[:space:]]*location[[:space:]]*//' | sed 's/[[:space:]]*{.*$//')
      paths+=("$path")
      echo "$((++count)). $DOMAIN$path"
    fi
  done <"/etc/nginx/sites-available/path-proxy"

  if [[ $count -eq 0 ]]; then
    echo "没有找到路径代理配置"
    return
  fi

  read -p "请选择要删除的配置 (1-$count): " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
    local path=${paths[$((choice - 1))]}

    read -p "确认删除 $DOMAIN$path 的代理配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # 删除路径配置
      sed -i "/^[[:space:]]*location[[:space:]]*$path[[:space:]]*{/,/^[[:space:]]*}/d" "/etc/nginx/sites-available/path-proxy"

      # 重载nginx
      nginx -t && systemctl reload nginx

      log "已删除路径代理配置: $DOMAIN$path"
    fi
  else
    echo -e "${RED}无效选择${NC}"
  fi
}

# 重新生成所有代理配置
regenerate_proxy_configs() {
  echo -e "${CYAN}=== 重新生成代理配置 ===${NC}"

  read -p "确认重新生成所有代理配置? 这将删除现有配置 (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    return
  fi

  # 备份现有配置
  backup_proxy_configs

  # 删除现有配置
  rm -f /etc/nginx/sites-enabled/*

  # 重新创建默认配置
  ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

  log "已重新生成代理配置，请重新添加所需的代理配置"
}

# 测试代理配置
test_proxy_configs() {
  echo -e "${CYAN}=== 测试代理配置 ===${NC}"

  # 测试nginx配置
  echo "测试Nginx配置..."
  if nginx -t; then
    echo -e "${GREEN}Nginx配置测试通过${NC}"
  else
    echo -e "${RED}Nginx配置测试失败${NC}"
    return
  fi

  # 测试服务状态
  echo "检查服务状态..."
  if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}Nginx服务运行正常${NC}"
  else
    echo -e "${RED}Nginx服务未运行${NC}"
  fi

  # 测试端口
  echo "检查端口监听..."
  if netstat -tuln | grep -q ":80 "; then
    echo -e "${GREEN}端口80监听正常${NC}"
  else
    echo -e "${RED}端口80未监听${NC}"
  fi

  if netstat -tuln | grep -q ":443 "; then
    echo -e "${GREEN}端口443监听正常${NC}"
  else
    echo -e "${YELLOW}端口443未监听（可能未配置SSL）${NC}"
  fi
}

# 备份代理配置
backup_proxy_configs() {
  local backup_dir="/root/proxy-backups"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_file="$backup_dir/proxy-config-$timestamp.tar.gz"

  mkdir -p "$backup_dir"

  tar -czf "$backup_file" -C /etc/nginx sites-available sites-enabled 2>/dev/null || true

  log "代理配置已备份到: $backup_file"
}

# 恢复代理配置
restore_proxy_configs() {
  local backup_dir="/root/proxy-backups"

  if [[ ! -d "$backup_dir" ]]; then
    echo "没有找到备份目录"
    return
  fi

  echo -e "${YELLOW}可用的备份文件:${NC}"
  local count=0
  local backups=()

  for backup in "$backup_dir"/proxy-config-*.tar.gz; do
    if [[ -f "$backup" ]]; then
      backups+=("$backup")
      echo "$((++count)). $(basename "$backup")"
    fi
  done

  if [[ $count -eq 0 ]]; then
    echo "没有找到备份文件"
    return
  fi

  read -p "请选择要恢复的备份 (1-$count): " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
    local backup_file=${backups[$((choice - 1))]}

    read -p "确认恢复备份 $backup_file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # 恢复配置
      tar -xzf "$backup_file" -C /etc/nginx

      # 重载nginx
      nginx -t && systemctl reload nginx

      log "已恢复代理配置: $backup_file"
    fi
  else
    echo -e "${RED}无效选择${NC}"
  fi
}

# 主函数
main() {
  check_root
  load_config

  while true; do
    show_menu
    read -p "请选择操作 (1-9): " choice

    case $choice in
    1)
      add_subdomain_proxy
      ;;
    2)
      add_path_proxy
      ;;
    3)
      show_proxy_configs
      ;;
    4)
      delete_proxy_config
      ;;
    5)
      regenerate_proxy_configs
      ;;
    6)
      test_proxy_configs
      ;;
    7)
      backup_proxy_configs
      ;;
    8)
      restore_proxy_configs
      ;;
    9)
      echo -e "${GREEN}退出管理工具${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}无效选择，请重新输入${NC}"
      ;;
    esac

    echo
    read -p "按回车键继续..."
  done
}

# 执行主函数
main "$@"
