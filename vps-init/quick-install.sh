#!/bin/bash

# ======================================================================
# == VPS 快速安装脚本                                              ==
# == 一键下载并执行VPS自动化配置脚本                                ==
# ======================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本信息
SCRIPT_NAME="VPS自动化配置脚本"
SCRIPT_VERSION="1.0"
SCRIPT_URL="https://raw.githubusercontent.com/MaelWeb/onekey-install-shell/main/vps-init/init.sh"
INSTALL_DIR="/root/vps-init"

# 显示欢迎信息
show_welcome() {
  echo -e "${BLUE}"
  echo "=========================================="
  echo "        $SCRIPT_NAME v$SCRIPT_VERSION"
  echo "=========================================="
  echo -e "${NC}"
  echo "此脚本将自动下载并执行VPS配置脚本"
  echo "支持的功能："
  echo "• Nginx高性能配置"
  echo "• X-UI VPN面板安装"
  echo "• SSL证书自动申请"
  echo "• 反向代理配置"
  echo "• 系统优化"
  echo
}

# 检查系统要求
check_requirements() {
  echo -e "${YELLOW}检查系统要求...${NC}"

  # 检查是否为root用户
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
    echo "请使用: sudo $0"
    exit 1
  fi

  # 检查网络连接
  if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${RED}错误: 无法连接到网络${NC}"
    exit 1
  fi

  # 检查必要工具
  for cmd in curl wget; do
    if ! command -v $cmd >/dev/null 2>&1; then
      echo -e "${YELLOW}安装 $cmd...${NC}"
      if command -v apt >/dev/null 2>&1; then
        apt update -y && apt install -y $cmd
      elif command -v yum >/dev/null 2>&1; then
        yum install -y $cmd
      else
        echo -e "${RED}错误: 无法安装 $cmd${NC}"
        exit 1
      fi
    fi
  done

  echo -e "${GREEN}系统要求检查通过${NC}"
}

# 下载脚本
download_script() {
  echo -e "${YELLOW}下载VPS配置脚本...${NC}"

  # 创建安装目录
  mkdir -p "$INSTALL_DIR"
  cd "$INSTALL_DIR"

  # 下载主脚本
  if curl -fsSL "$SCRIPT_URL" -o init.sh; then
    echo -e "${GREEN}脚本下载成功${NC}"
  else
    echo -e "${RED}脚本下载失败${NC}"
    echo "尝试备用下载方式..."
    if wget -q "$SCRIPT_URL" -O init.sh; then
      echo -e "${GREEN}脚本下载成功${NC}"
    else
      echo -e "${RED}所有下载方式都失败了${NC}"
      exit 1
    fi
  fi

  # 设置执行权限
  chmod +x init.sh

  echo -e "${GREEN}脚本准备完成${NC}"
}

# 显示安装选项
show_options() {
  echo -e "${CYAN}安装选项:${NC}"
  echo "1. 完整安装 (推荐)"
  echo "2. 仅安装Nginx"
  echo "3. 仅安装X-UI"
  echo "4. 仅系统优化"
  echo "5. 退出"
  echo
}

# 执行安装
execute_installation() {
  local option=$1

  case $option in
  1)
    echo -e "${GREEN}开始完整安装...${NC}"
    ./init.sh
    ;;
  2)
    echo -e "${GREEN}开始Nginx安装...${NC}"
    # 这里可以添加仅安装Nginx的逻辑
    echo "功能开发中..."
    ;;
  3)
    echo -e "${GREEN}开始X-UI安装...${NC}"
    # 这里可以添加仅安装X-UI的逻辑
    echo "功能开发中..."
    ;;
  4)
    echo -e "${GREEN}开始系统优化...${NC}"
    # 这里可以添加仅系统优化的逻辑
    echo "功能开发中..."
    ;;
  5)
    echo -e "${YELLOW}退出安装${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}无效选项${NC}"
    return 1
    ;;
  esac
}

# 显示完成信息
show_completion() {
  echo -e "${GREEN}"
  echo "=========================================="
  echo "           安装完成！"
  echo "=========================================="
  echo -e "${NC}"

  echo -e "${CYAN}重要信息:${NC}"
  echo "• 安装目录: $INSTALL_DIR"
  echo "• 配置文件: $INSTALL_DIR/vps_config.json"
  echo "• 安装日志: $INSTALL_DIR/vps_setup.log"
  echo
  echo -e "${CYAN}管理命令:${NC}"
  echo "• vps-manager status    - 查看服务状态"
  echo "• vps-manager restart   - 重启服务"
  echo "• vps-manager logs      - 查看日志"
  echo "• vps-manager backup    - 备份配置"
  echo
  echo -e "${YELLOW}注意事项:${NC}"
  echo "• 请及时修改X-UI面板的默认密码"
  echo "• 定期备份配置文件"
  echo "• 监控系统资源使用情况"
}

# 主函数
main() {
  show_welcome

  # 检查系统要求
  check_requirements

  # 下载脚本
  download_script

  # 显示选项并执行
  while true; do
    show_options
    read -p "请选择安装选项 (1-5): " choice

    if execute_installation "$choice"; then
      break
    fi
  done

  # 显示完成信息
  show_completion
}

# 处理命令行参数
case "${1:-}" in
--help | -h)
  echo "用法: $0 [选项]"
  echo "选项:"
  echo "  --help, -h     显示帮助信息"
  echo "  --version, -v  显示版本信息"
  echo "  --auto         自动执行完整安装"
  exit 0
  ;;
--version | -v)
  echo "$SCRIPT_NAME v$SCRIPT_VERSION"
  exit 0
  ;;
--auto)
  show_welcome
  check_requirements
  download_script
  cd "$INSTALL_DIR"
  ./init.sh
  show_completion
  exit 0
  ;;
"")
  # 交互模式
  main
  ;;
*)
  echo -e "${RED}未知选项: $1${NC}"
  echo "使用 --help 查看帮助信息"
  exit 1
  ;;
esac
