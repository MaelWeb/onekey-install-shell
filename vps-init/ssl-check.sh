#!/bin/bash

# ======================================================================
# == SSL证书申请前置条件检查脚本                                    ==
# == 检查所有acme.sh证书申请必需的条件                            ==
# ======================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
ACME_DIR="/root/.acme.sh"
LOG_FILE="/var/log/ssl-check.log"

# 日志函数
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
  echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

info() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# 检查系统信息
check_system_info() {
  echo -e "${BLUE}=== 系统信息 ===${NC}"

  # 操作系统
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "操作系统: $NAME $VERSION_ID"
  else
    echo "操作系统: 未知"
  fi

  # 架构
  echo "架构: $(uname -m)"

  # 内核版本
  echo "内核版本: $(uname -r)"

  # 服务器IP
  if command -v curl >/dev/null 2>&1; then
    local server_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || curl -s --max-time 10 ipinfo.io/ip 2>/dev/null)
    if [[ -n "$server_ip" ]]; then
      echo "服务器公网IP: $server_ip"
    fi
  fi

  echo
}

# 检查域名DNS解析
check_dns_resolution() {
  local domain="$1"
  echo -e "${BLUE}=== DNS解析检查 ===${NC}"

  if [[ -z "$domain" ]]; then
    echo "未提供域名，跳过DNS检查"
    return 0
  fi

  # 检查域名格式
  if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    error "域名格式不正确: $domain"
    return 1
  fi

  echo "检查域名: $domain"

  # 使用dig检查
  if command -v dig >/dev/null 2>&1; then
    local resolved_ip=$(dig +short "$domain" | head -1)
    if [[ -n "$resolved_ip" ]]; then
      echo "✅ DNS解析成功: $domain -> $resolved_ip"

      # 检查是否解析到服务器IP
      if command -v curl >/dev/null 2>&1; then
        local server_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || curl -s --max-time 10 ipinfo.io/ip 2>/dev/null)
        if [[ -n "$server_ip" && "$resolved_ip" != "$server_ip" ]]; then
          warn "域名解析的IP ($resolved_ip) 与服务器IP ($server_ip) 不匹配"
        else
          echo "✅ 域名解析IP与服务器IP匹配"
        fi
      fi
    else
      error "DNS解析失败: $domain"
      return 1
    fi
  else
    warn "未找到dig命令，无法进行DNS检查"
  fi

  echo
}

# 检查端口可用性
check_port_availability() {
  echo -e "${BLUE}=== 端口可用性检查 ===${NC}"

  # 检查80端口
  if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    local port80_process=$(netstat -tlnp 2>/dev/null | grep ":80 " | awk '{print $7}' | cut -d'/' -f2)
    if [[ "$port80_process" == "nginx" ]]; then
      echo "✅ 80端口被nginx占用（正常，申请证书时会临时停止）"
    else
      warn "80端口被 $port80_process 占用，可能影响证书申请"
    fi
  else
    echo "✅ 80端口可用"
  fi

  # 检查443端口
  if netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    local port443_process=$(netstat -tlnp 2>/dev/null | grep ":443 " | awk '{print $7}' | cut -d'/' -f2)
    echo "ℹ️  443端口被 $port443_process 占用"
  else
    echo "✅ 443端口可用"
  fi

  echo
}

# 检查防火墙设置
check_firewall() {
  echo -e "${BLUE}=== 防火墙检查 ===${NC}"

  # 检测操作系统
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
  fi

  case $ID in
  ubuntu | debian)
    if command -v ufw >/dev/null 2>&1; then
      if ufw status | grep -q "Status: active"; then
        echo "防火墙状态: 启用"
        if ufw status | grep -q "80/tcp.*ALLOW"; then
          echo "✅ 80端口已允许"
        else
          warn "80端口可能被防火墙阻止"
        fi
        if ufw status | grep -q "443/tcp.*ALLOW"; then
          echo "✅ 443端口已允许"
        else
          warn "443端口可能被防火墙阻止"
        fi
      else
        echo "防火墙状态: 禁用"
      fi
    else
      echo "未安装ufw防火墙"
    fi
    ;;
  centos | rhel | almalinux | rocky)
    if command -v firewall-cmd >/dev/null 2>&1; then
      if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        echo "防火墙状态: 启用"
        if firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp"; then
          echo "✅ 80端口已允许"
        else
          warn "80端口可能被防火墙阻止"
        fi
        if firewall-cmd --list-ports 2>/dev/null | grep -q "443/tcp"; then
          echo "✅ 443端口已允许"
        else
          warn "443端口可能被防火墙阻止"
        fi
      else
        echo "防火墙状态: 禁用"
      fi
    else
      echo "未安装firewalld防火墙"
    fi
    ;;
  *)
    echo "未知操作系统，无法检查防火墙"
    ;;
  esac

  echo
}

# 检查网络连接
check_network() {
  echo -e "${BLUE}=== 网络连接检查 ===${NC}"

  # 检查基本网络连接
  if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ 外网连接正常"
  else
    error "无法连接到外网"
    return 1
  fi

  # 检查Let's Encrypt服务器连接
  if curl -s --max-time 10 https://acme-v02.api.letsencrypt.org/directory >/dev/null 2>&1; then
    echo "✅ Let's Encrypt服务器连接正常"
  else
    error "无法连接到Let's Encrypt服务器"
    return 1
  fi

  echo
}

# 检查必要工具
check_required_tools() {
  echo -e "${BLUE}=== 必要工具检查 ===${NC}"

  local missing_tools=()
  local required_tools=("openssl" "curl" "socat" "netstat")

  for tool in "${required_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "✅ $tool: 已安装"
    else
      echo "❌ $tool: 未安装"
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    warn "缺少必要工具: ${missing_tools[*]}"
    echo "建议安装命令:"
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case $ID in
      ubuntu | debian)
        echo "  apt install -y ${missing_tools[*]}"
        ;;
      centos | rhel | almalinux | rocky)
        echo "  yum install -y ${missing_tools[*]}"
        ;;
      esac
    fi
  fi

  echo
}

# 检查acme.sh安装
check_acme_installation() {
  echo -e "${BLUE}=== acme.sh安装检查 ===${NC}"

  if [[ -d "$ACME_DIR" ]]; then
    echo "✅ acme.sh已安装"
    if [[ -f "$ACME_DIR/acme.sh" ]]; then
      echo "✅ acme.sh脚本存在"
      # 检查版本
      local version=$("$ACME_DIR/acme.sh" --version 2>/dev/null | head -1)
      if [[ -n "$version" ]]; then
        echo "版本: $version"
      fi
    else
      error "acme.sh脚本不存在"
      return 1
    fi
  else
    error "acme.sh未安装"
    echo "安装命令: curl https://get.acme.sh | sh -s email=your-email@example.com"
    return 1
  fi

  echo
}

# 检查磁盘空间
check_disk_space() {
  echo -e "${BLUE}=== 磁盘空间检查 ===${NC}"

  local ssl_dir="/etc/nginx/ssl"
  if [[ ! -d "$ssl_dir" ]]; then
    mkdir -p "$ssl_dir"
  fi

  local available_space=$(df "$ssl_dir" 2>/dev/null | tail -1 | awk '{print $4}')
  if [[ -n "$available_space" ]]; then
    local available_mb=$((available_space / 1024))
    echo "SSL目录可用空间: ${available_mb}MB"

    if [[ $available_mb -lt 10 ]]; then
      warn "磁盘空间不足（小于10MB），可能影响证书存储"
    else
      echo "✅ 磁盘空间充足"
    fi
  else
    warn "无法获取磁盘空间信息"
  fi

  echo
}

# 检查域名可访问性
check_domain_accessibility() {
  local domain="$1"
  echo -e "${BLUE}=== 域名可访问性检查 ===${NC}"

  if [[ -z "$domain" ]]; then
    echo "未提供域名，跳过可访问性检查"
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    echo "检查域名: $domain"
    local http_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$domain" 2>/dev/null)

    if [[ "$http_response" == "000" ]]; then
      warn "域名 $domain 无法通过HTTP访问"
      echo "可能原因:"
      echo "  - 域名未正确解析"
      echo "  - 服务器防火墙阻止"
      echo "  - nginx未运行"
    else
      echo "✅ 域名 $domain 可以正常访问 (HTTP状态码: $http_response)"
    fi
  else
    warn "未找到curl命令，无法检查域名可访问性"
  fi

  echo
}

# 生成检查报告
generate_report() {
  local domain="$1"
  echo -e "${BLUE}=== SSL证书申请前置条件检查报告 ===${NC}"
  echo "检查时间: $(date)"
  echo "检查域名: ${domain:-'未指定'}"
  echo "日志文件: $LOG_FILE"
  echo

  # 执行所有检查
  check_system_info
  check_dns_resolution "$domain"
  check_port_availability
  check_firewall
  check_network
  check_required_tools
  check_acme_installation
  check_disk_space
  check_domain_accessibility "$domain"

  echo -e "${BLUE}=== 检查完成 ===${NC}"
  echo "详细日志请查看: $LOG_FILE"
}

# 显示帮助信息
show_help() {
  echo "SSL证书申请前置条件检查脚本"
  echo
  echo "用法: $0 [选项] [域名]"
  echo
  echo "选项:"
  echo "  -h, --help     显示此帮助信息"
  echo "  -d, --domain   指定要检查的域名"
  echo "  -v, --verbose  详细输出模式"
  echo
  echo "示例:"
  echo "  $0                    # 检查系统环境（不检查特定域名）"
  echo "  $0 example.com        # 检查example.com域名的前置条件"
  echo "  $0 -d api.example.com # 检查api.example.com域名的前置条件"
  echo
  echo "检查项目:"
  echo "  - 系统信息"
  echo "  - DNS解析"
  echo "  - 端口可用性"
  echo "  - 防火墙设置"
  echo "  - 网络连接"
  echo "  - 必要工具"
  echo "  - acme.sh安装"
  echo "  - 磁盘空间"
  echo "  - 域名可访问性"
}

# 主函数
main() {
  local domain=""
  local verbose=false

  # 解析命令行参数
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      show_help
      exit 0
      ;;
    -d | --domain)
      domain="$2"
      shift 2
      ;;
    -v | --verbose)
      verbose=true
      shift
      ;;
    -*)
      echo "未知选项: $1"
      show_help
      exit 1
      ;;
    *)
      if [[ -z "$domain" ]]; then
        domain="$1"
      else
        echo "错误: 只能指定一个域名"
        exit 1
      fi
      shift
      ;;
    esac
  done

  # 创建日志目录
  mkdir -p "$(dirname "$LOG_FILE")"

  # 生成检查报告
  generate_report "$domain"
}

# 执行主函数
main "$@"
