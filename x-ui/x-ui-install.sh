#!/bin/bash

#====================================================
#	System Request:Debian 9+/Ubuntu 18.04+/Centos 7+
#	Author:	ygkkk
#	Dscription: X-ui-yg script
#	email: ygkkk2022@gmail.com
#====================================================

#====================================================
#               公共配置变量
# 通过修改这些变量,可以自定义安装路径和名称,以避免冲突
#====================================================
PANEL_NAME="x-ui-yg"  # 面板名称，用于服务名、目录名等
#----------------------------------------------------
# 以下变量通常无需修改
INSTALL_DIR="/usr/local/${PANEL_NAME}" # 安装目录
CONFIG_DIR="/etc/${PANEL_NAME}"       # 配置文件目录
SERVICE_NAME="${PANEL_NAME}"          # Systemd服务名
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service" # Systemd服务文件路径
BIN_PATH="/usr/bin/${PANEL_NAME}"     # 快捷方式路径
CORE_EXEC_PATH="${INSTALL_DIR}/x-ui"  # 主程序执行路径
#====================================================


red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}

white(){
    echo -e "\033[37m\033[01m$1\033[0m"
}

bblue(){
    echo -e "\033[34m\033[01m\033[05m$1\033[0m"
}

rred(){
    echo -e "\033[31m\033[01m\033[05m$1\033[0m"
}

#panel
ver="v1.8.11"
changeLog="1. 同步x-ui v1.8.11版本；"
arch=`uname -m`
#github_down_url=https://github.com/yonggekkk/x-ui-yg/releases/download/${ver}
github_down_url=https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main
#gitee_down_url=https://gitee.com/ygkkk/x-ui-yg/releases/download/${ver}
last_version=
latest_version=

if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    red "不支持的系统"
    exit 1
fi

if ! type curl >/dev/null 2>&1; then 
yellow "curl 未安装，正在安装中"
if [ $release = "centos" ]; then
yum install curl -y >/dev/null 2>&1
else
apt install curl -y >/dev/null 2>&1
fi
fi

if ! type wget >/dev/null 2>&1; then 
yellow "wget 未安装，正在安装中"
if [ $release = "centos" ]; then
yum install wget -y >/dev/null 2>&1
else
apt install wget -y >/dev/null 2>&1
fi
fi

if ! type tar >/dev/null 2>&1; then 
yellow "tar 未安装，正在安装中"
if [ $release = "centos" ]; then
yum install tar -y >/dev/null 2>&1
else
apt install tar -y >/dev/null 2>&1
fi
fi

readp(){
	read -p "$1" $2
}

if [[ $EUID -ne 0 ]]; then
    red "请在root用户下运行脚本"
    exit 1
fi

serinstall(){
	if [ "$arch" == "x86_64" ]; then
		arch="amd64"
	elif [ "$arch" == "aarch64" ]; then
		arch="arm64"
	fi

	cp ${INSTALL_DIR}/x-ui.service ${SERVICE_FILE}
 	sed -i "s/User=root/User=root/g" ${SERVICE_FILE}
	sed -i "s#/usr/local/x-ui/#${INSTALL_DIR}/#g" ${SERVICE_FILE}
	
	systemctl daemon-reload
	systemctl enable ${SERVICE_NAME}
	
	#设置快捷方式
	rm ${BIN_PATH} -f
	ln -s ${CORE_EXEC_PATH} ${BIN_PATH}
}

check_status(){
    if [[ ! -f ${SERVICE_FILE} ]]; then
        return 2
    fi
    status=`systemctl is-active ${SERVICE_NAME}`
    if [[ "$status" = "active" ]]; then
        return 0
    else
        return 1
    fi
}

start_menu(){
	clear
	red "=============================================================="
	red "  甬哥侃侃侃(ygkkk) x-ui 修改版脚本(2024.03.18)，支持多用户多协议"
	red "  ** 本脚本仅限于学习交流，请勿用于非法用途  **"
	red "=============================================================="
	green "  简介：x-ui 精简修改版，支持最新的 Xray-core"
	green "  功能：argo 固定、临时隧道；warp索套、warp解锁"
	green "  功能：psiphon(赛风)VPN(30个国家)、gost隧道加密"
	green "  功能：节点配置(clash-meta、sing-box、v2rayN)输出"
	green "  功能：reality协议一键安装"
	green "  TG频道：t.me/ygkkk        博客：ygkkk.blogspot.com"
	white "=============================================================="
	blue "  ${PANEL_NAME} $ver x-ray-core v1.8.8"
	blue "  $changeLog"
	white "=============================================================="
	yellow "  1. 安装 ${PANEL_NAME}"
	yellow "  2. 卸载 ${PANEL_NAME}"
	white "--------------------------------------------------------------"
	yellow "  3. 启动 ${PANEL_NAME}"
	yellow "  4. 停止 ${PANEL_NAME}"
	yellow "  5. 重启 ${PANEL_NAME}"
	white "--------------------------------------------------------------"
	yellow "  6. 更新 ${PANEL_NAME}"
	yellow "  7. 重置 ${PANEL_NAME} 所有设置"
	white "--------------------------------------------------------------"
	yellow "  8. 退出"
	white "=============================================================="
	check_status
	if [[ $? == 0 ]]; then
		blue "当前状态：\033[42;37m已安装\033[0m"
		green "${PANEL_NAME} 运行中"
	elif [[ $? == 1 ]]; then
		blue "当前状态：\033[42;37m已安装\033[0m"
		red "${PANEL_NAME} 已停止"
	elif [[ $? == 2 ]]; then
		blue "当前状态：\033[41;37m未安装\033[0m"
	fi
	echo ""
	readp "请输入数字[1-8]：" ins
	case "$ins" in
		1) install ;;
		2) uninstall ;;
		3) start ;;
		4) stop ;;
		5) restart ;;
		6) update ;;
		7) reset_config ;;
		8) exit 0 ;;
		*) red "请输入正确的数字" && sleep 1 && start_menu
	esac
}

install(){
	if [[ -f ${SERVICE_FILE} ]]; then
		red "${PANEL_NAME} 已安装，请勿重复安装"
		sleep 2
		start_menu
	fi
	
	if [ "$arch" == "x86_64" ]; then
		arch="amd64"
	elif [ "$arch" == "aarch64" ]; then
		arch="arm64"
	fi
 
	if [ -d "${INSTALL_DIR}/" ]; then
		rm -rf ${INSTALL_DIR}/
	fi

	if [ ! -d "${INSTALL_DIR}/" ]; then
		mkdir -p ${INSTALL_DIR}
	fi
	
	if [ ! -d "${CONFIG_DIR}/" ]; then
		mkdir -p ${CONFIG_DIR}
	fi
	
    wget -N --no-check-certificate -O ${INSTALL_DIR}/x-ui-linux-${arch}.tar.gz ${github_down_url}/x-ui-linux-${arch}.tar.gz
    tar -zxvf ${INSTALL_DIR}/x-ui-linux-${arch}.tar.gz -C ${INSTALL_DIR}
    chmod +x ${CORE_EXEC_PATH}
    ${CORE_EXEC_PATH} -v > ${INSTALL_DIR}/v
 
	rm ${INSTALL_DIR}/x-ui-linux-${arch}.tar.gz -f
	
	serinstall
	
	readp "是否设置 ${PANEL_NAME} 登录用户名、密码、端口(默认随机) [y/n]:" para
	if [[ "$para" == "y" ]] || [[ "$para" == "Y" ]]; then
		readp "请输入用户名(默认admin)：" username
		readp "请输入密码(默认admin)：" password
		readp "请输入端口号(默认54321)：" port
	fi
	if [[ -z $username ]]; then
		username="admin"
	fi
	if [[ -z $password ]]; then
		password="admin"
	fi
	if [[ -z $port ]]; then
		port=54321
	fi
	
	${CORE_EXEC_PATH} setting -username ${username} -password ${password} -port ${port} -configdir ${CONFIG_DIR} >/dev/null 2>&1
	
	crontab -l > /tmp/crontab.tmp
	echo "0 4 * * * ${BIN_PATH}" >> /tmp/crontab.tmp
	crontab /tmp/crontab.tmp
	rm /tmp/crontab.tmp
	
	systemctl start ${SERVICE_NAME}
	
	yellow "${PANEL_NAME} 安装成功"
	white "--------------------------------------------------------------"
	blue "面板地址：http://$(curl -s https://ipinfo.io/ip):${port}"
	blue "用户名：${username}"
	blue "密码：${password}"
	white "--------------------------------------------------------------"
	blue "管理命令: ${PANEL_NAME} [start|stop|restart|status|update|uninstall]"
	blue "快捷命令: ${PANEL_NAME}"
	white "--------------------------------------------------------------"
	start_menu
}

update(){
	last_version=`${CORE_EXEC_PATH} -v | head -n 1`
	latest_version=`curl -sL https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/version | head -n 1`
	
	if [[ -z $latest_version ]]; then
		red "${PANEL_NAME} 更新失败"
		red "请检查网络或稍后再试"
		sleep 2
		start_menu
	fi
	
	if [ "$last_version" == "$latest_version" ]; then
		green "当前版本为最新版本"
		sleep 2
		start_menu
	fi
	
	yellow "本次更新将清除所有设置，建议如下："
	yellow "一、点击x-ui面版中的备份与恢复，下载备份文件x-ui-yg.db"
	yellow "二、在 ${CONFIG_DIR} 路径导出备份文件x-ui-yg.db"
	readp "确定升级，请按回车(退出请按ctrl+c):" ins
	if [[ -z $ins ]]; then
		systemctl stop ${SERVICE_NAME}
		
		serinstall && sleep 2
		
		restart
		
		curl -sL https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/version | awk -F "更新内容" '{print $1}' | head -n 1 > ${INSTALL_DIR}/v

		green "${PANEL_NAME} 更新完成" && sleep 2 && ${PANEL_NAME}
	else
		red "输入有误" && update
	fi
}

uninstall(){
	yellow "本次卸载将清除所有数据，建议如下："
	yellow "一、点击x-ui面版中的备份与恢复，下载备份文件x-ui-yg.db"
	yellow "二、在 ${CONFIG_DIR} 路径导出备份文件x-ui-yg.db"
	readp "确定卸载，请按回车(退出请按ctrl+c):" ins
	if [[ -z $ins ]]; then
		systemctl stop ${SERVICE_NAME}
		systemctl disable ${SERVICE_NAME}
		rm ${SERVICE_FILE} -f
		systemctl daemon-reload
		systemctl reset-failed
		
		kill -15 $(cat ${INSTALL_DIR}/xuiargopid.log 2>/dev/null) >/dev/null 2>&1
		kill -15 $(cat ${INSTALL_DIR}/xuiargoympid.log 2>/dev/null) >/dev/null 2>&1
		
		rm ${BIN_PATH} -f
		rm -rf ${CONFIG_DIR}/
		rm -rf ${INSTALL_DIR}/
		
		crontab -l > /tmp/crontab.tmp
		sed -i "/${PANEL_NAME}/d" /tmp/crontab.tmp
		crontab /tmp/crontab.tmp
		rm /tmp/crontab.tmp
		
		sed -i '/^precedence ::ffff:0:0\/96  100/d' /etc/gai.conf 2>/dev/null
		
		echo ""
		green "${PANEL_NAME} 已卸载完成"
		echo ""
		blue "欢迎继续使用此脚本"
		echo ""
	else
		red "输入有误" && uninstall
	fi
}

reset_config(){
	${BIN_PATH} setting -reset
	sleep 1
	portinstall
}

start(){
    systemctl start ${SERVICE_NAME}
	check_status
	if [[ $? == 0 ]]; then
		crontab -l > /tmp/crontab.tmp
		echo "0 4 * * * ${BIN_PATH}" >> /tmp/crontab.tmp
		crontab /tmp/crontab.tmp
		rm /tmp/crontab.tmp
		green "${PANEL_NAME} 启动成功"
	else
		red "${PANEL_NAME} 启动失败"
		red "请检查日志"
		${BIN_PATH} log
	fi
	start_menu
}

stop(){
	systemctl stop ${SERVICE_NAME}
	check_status
	if [[ $? == 1 ]]; then
		crontab -l > /tmp/crontab.tmp
		sed -i "/goxui.sh/d" /tmp/crontab.tmp
		crontab /tmp/crontab.tmp
		rm /tmp/crontab.tmp
		green "${PANEL_NAME} 停止成功"
	else
		red "${PANEL_NAME} 停止失败"
	fi
	start_menu
}

restart(){
    systemctl restart ${SERVICE_NAME}
	check_status
	if [[ $? == 0 ]]; then
		green "${PANEL_NAME} 重启成功"
	else
		red "${PANEL_NAME} 重启失败"
		red "请检查日志"
		${BIN_PATH} log
	fi
	start_menu
}

start_menu
