<!--
 * @Author: edenliang edenliang@tencent.com
 * @Date: 2025-06-22 00:09:36
 * @LastEditors: edenliang edenliang@tencent.com
 * @LastEditTime: 2025-06-22 00:13:10
 * @FilePath: /onekey-install-shell/x-ui/README.md
 * @Description: X-UI 一键安装脚本使用说明
-->

# X-UI 一键安装脚本

## 📖 项目简介

X-UI 是一个基于 Xray-core 的多用户多协议代理面板，本脚本提供了便捷的一键安装、管理和维护功能。脚本基于 ygkkk 的修改版本，支持最新的 Xray-core v1.8.8。

## ✨ 主要功能

### 🔧 核心功能
- **多用户多协议支持**：支持多种代理协议，满足不同用户需求
- **Web 管理面板**：提供直观的 Web 界面进行配置管理
- **自动安装部署**：一键安装，自动配置系统服务
- **定时任务管理**：自动设置定时重启任务

### 🌐 协议支持
- **Argo 隧道**：固定和临时隧道支持
- **Warp 套件**：Warp 索套和 Warp 解锁功能
- **Psiphon VPN**：支持 30 个国家的赛风 VPN
- **Gost 隧道**：隧道加密功能
- **Reality 协议**：一键安装 Reality 协议

### 📱 客户端配置
- **Clash Meta**：支持 Clash Meta 配置导出
- **Sing-box**：支持 Sing-box 配置导出
- **V2rayN**：支持 V2rayN 配置导出

## 🛠️ 系统要求

### 支持的操作系统
- **Debian 9+**
- **Ubuntu 18.04+**
- **CentOS 7+**

### 硬件架构
- **x86_64 (amd64)**
- **aarch64 (arm64)**

### 权限要求
- 需要 **root 权限** 运行安装脚本

## 🚀 快速开始

### 1. 下载脚本
```bash
# 克隆项目或下载脚本文件
wget -O x-ui-install.sh https://raw.githubusercontent.com/your-repo/x-ui/x-ui-install.sh
```

### 2. 执行安装
```bash
# 给脚本执行权限
chmod +x x-ui-install.sh

# 运行安装脚本
sudo bash x-ui-install.sh
```

### 3. 选择安装选项
脚本启动后会显示主菜单，选择相应的数字进行操作：

```
==============================================================
  甬哥侃侃侃(ygkkk) x-ui 修改版脚本(2024.03.18)，支持多用户多协议
  ** 本脚本仅限于学习交流，请勿用于非法用途  **
==============================================================
  简介：x-ui 精简修改版，支持最新的 Xray-core
  功能：argo 固定、临时隧道；warp索套、warp解锁
  功能：psiphon(赛风)VPN(30个国家)、gost隧道加密
  功能：节点配置(clash-meta、sing-box、v2rayN)输出
  功能：reality协议一键安装
  TG频道：t.me/ygkkk        博客：ygkkk.blogspot.com
==============================================================
  x-ui-yg v1.8.11 x-ray-core v1.8.8
  1. 同步x-ui v1.8.11版本；
==============================================================
  1. 安装 x-ui-yg
  2. 卸载 x-ui-yg
--------------------------------------------------------------
  3. 启动 x-ui-yg
  4. 停止 x-ui-yg
  5. 重启 x-ui-yg
--------------------------------------------------------------
  6. 更新 x-ui-yg
  7. 重置 x-ui-yg 所有设置
--------------------------------------------------------------
  8. 退出
==============================================================
```

## 📋 详细使用指南

### 安装过程

1. **选择安装选项**：在主菜单中选择 `1` 进行安装
2. **配置参数**（可选）：
   - 是否自定义登录信息：`y/n`
   - 用户名（默认：admin）
   - 密码（默认：admin）
   - 端口号（默认：54321）
3. **等待安装完成**：脚本会自动下载、解压、配置服务

### 安装完成后的信息

安装成功后，脚本会显示以下信息：

```
x-ui-yg 安装成功
--------------------------------------------------------------
面板地址：http://YOUR_SERVER_IP:54321
用户名：admin
密码：admin
--------------------------------------------------------------
管理命令: x-ui-yg [start|stop|restart|status|update|uninstall]
快捷命令: x-ui-yg
--------------------------------------------------------------
```

### 访问管理面板

1. 在浏览器中访问：`http://YOUR_SERVER_IP:54321`
2. 使用默认凭据登录：
   - 用户名：`admin`
   - 密码：`admin`

## 🔧 管理命令

### 系统服务管理
```bash
# 启动服务
x-ui-yg start

# 停止服务
x-ui-yg stop

# 重启服务
x-ui-yg restart

# 查看状态
x-ui-yg status
```

### 其他管理操作
```bash
# 更新到最新版本
x-ui-yg update

# 卸载程序
x-ui-yg uninstall

# 查看日志
x-ui-yg log
```

## 📁 文件结构

安装完成后，系统会创建以下目录和文件：

```
/usr/local/x-ui-yg/          # 主程序目录
├── x-ui                     # 主程序文件
├── x-ui.service            # 系统服务文件
└── v                       # 版本信息

/etc/x-ui-yg/               # 配置文件目录
└── x-ui-yg.db             # 数据库文件

/etc/systemd/system/x-ui-yg.service  # 系统服务文件
/usr/bin/x-ui-yg           # 快捷命令
```

## 🔄 更新和备份

### 更新前准备
在更新前，建议进行数据备份：

1. **通过 Web 面板备份**：
   - 登录管理面板
   - 进入"备份与恢复"页面
   - 下载备份文件 `x-ui-yg.db`

2. **直接备份数据库文件**：
   ```bash
   cp /etc/x-ui-yg/x-ui-yg.db /backup/x-ui-yg.db
   ```

### 执行更新
```bash
# 运行脚本选择更新选项
sudo bash x-ui-install.sh
# 选择选项 6 进行更新
```

## 🛡️ 安全建议

### 基本安全措施
1. **修改默认密码**：安装后立即修改默认的 admin/admin 密码
2. **更改默认端口**：考虑修改默认的 54321 端口
3. **防火墙配置**：确保只开放必要的端口
4. **定期备份**：定期备份配置文件和数据

### 防火墙配置示例
```bash
# Ubuntu/Debian
ufw allow 54321/tcp
ufw enable

# CentOS
firewall-cmd --permanent --add-port=54321/tcp
firewall-cmd --reload
```

## 🐛 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 查看详细日志
   x-ui-yg log
   
   # 检查服务状态
   systemctl status x-ui-yg
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep 54321
   
   # 修改端口后重启服务
   x-ui-yg setting -port 54322
   x-ui-yg restart
   ```

3. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x x-ui-install.sh
   
   # 确保以 root 用户运行
   sudo bash x-ui-install.sh
   ```

### 日志查看
```bash
# 查看实时日志
x-ui-yg log

# 查看系统服务日志
journalctl -u x-ui-yg -f
```

## 📞 技术支持

### 官方资源
- **Telegram 频道**：t.me/ygkkk
- **博客**：ygkkk.blogspot.com
- **GitHub**：https://github.com/yonggekkk/x-ui-yg

### 版本信息
- **当前版本**：v1.8.11
- **Xray-core 版本**：v1.8.8
- **最后更新**：2024.03.18

## ⚠️ 免责声明

本脚本仅供学习和研究使用，请遵守当地法律法规。使用者需要自行承担使用风险，开发者不承担任何法律责任。

## 📄 许可证

本项目基于开源许可证发布，具体许可证信息请参考项目源码。

---

**注意**：使用前请确保您了解相关法律法规，并遵守当地的使用政策。
