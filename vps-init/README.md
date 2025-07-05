# VPS 自动化配置脚本

一个功能强大的 VPS 自动化配置脚本，支持交互式操作，用于快速配置生产级 VPS 服务器。

## 🚀 功能特性

### 核心功能

- ✅ **Nginx 高性能配置** - 自动优化配置，支持 HTTP/2、Gzip 压缩、安全头
- ✅ **X-UI VPN 面板** - 使用 [yonggekkk/x-ui-yg](https://github.com/yonggekkk/x-ui-yg) 安装
- ✅ **SSL 证书管理** - 使用 acme.sh 自动申请和续期 Let's Encrypt 证书，包含全面的前置条件检查
- ✅ **反向代理配置** - 支持子域名代理和路径代理两种方式
- ✅ **防火墙配置** - 自动配置 UFW 或 firewalld
- ✅ **系统优化** - 网络、内存、文件描述符等系统级优化

### 高级特性

- 🔧 **交互式配置** - 支持用户交互式输入域名和代理配置
- 🛡️ **安全加固** - 自动配置安全头、隐藏版本号、访问控制
- 📊 **性能优化** - 根据 VPS 配置自动优化 Nginx 和系统参数
- 🔄 **管理工具** - 提供便捷的服务管理命令
- 📝 **详细日志** - 完整的安装和配置日志记录
- 🔐 **SSL 前置条件检查** - 全面的 SSL 证书申请前置条件检查
- 🤖 **智能自动续期** - 基于 cron 的 SSL 证书自动续期系统
- 📋 **独立检查工具** - 可单独使用的 SSL 前置条件检查脚本

## 📋 系统要求

### 支持的操作系统

- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- AlmaLinux 8+
- Rocky Linux 8+

### 硬件要求

- **CPU**: 1 核心以上
- **内存**: 512MB 以上
- **存储**: 10GB 以上可用空间
- **网络**: 稳定的网络连接

## 🛠️ 安装使用

### 1. 下载脚本

```bash
# 克隆项目
git clone https://github.com/MaelWeb/onekey-install-shell.git
cd onekey-install-shell/vps-init

# 或直接下载脚本
wget https://raw.githubusercontent.com/MaelWeb/onekey-install-shell/main/vps-init/init.sh

# 或
bash <(curl -Ls https://raw.githubusercontent.com/MaelWeb/onekey-install-shell/main/vps-init/init.sh)
```

### 2. 执行安装

```bash
# 给脚本执行权限
chmod +x init.sh

# 运行脚本（需要root权限）
sudo ./init.sh
```

### 3. 交互式配置

脚本运行后会引导您完成以下配置：

#### 域名配置

```
请输入主域名 (例如: example.com): your-domain.com
```

- 脚本会自动验证域名格式
- 检查 DNS 解析
- 申请 SSL 证书

#### 反向代理配置

脚本支持两种代理方式：

**子域名代理** (例如: api.example.com -> 127.0.0.1:3000)

```
请选择代理类型: 1
是否添加子域名代理配置? (y/N): y
请输入子域名 (例如: api): api
请输入后端服务地址 (例如: 127.0.0.1:8080): 127.0.0.1:3000
是否启用SSL? (Y/n): Y
是否支持WebSocket? (Y/n): Y
```

**路径代理** (例如: example.com/api -> 127.0.0.1:3000)

```
请选择代理类型: 2
是否添加路径代理配置? (y/N): y
请输入路径 (例如: /api): /api
请输入后端服务地址 (例如: 127.0.0.1:8080): 127.0.0.1:3000
是否支持WebSocket? (Y/n): Y
是否移除路径前缀? (y/N): N
```

## 🔧 管理命令

安装完成后，您可以使用以下命令管理服务：

```bash
# 查看服务状态
vps-manager status

# 重启服务
vps-manager restart

# 查看实时日志
vps-manager logs

# 更新SSL证书
vps-manager ssl-renew

# 检查SSL证书状态
vps-manager ssl-status

# 检查SSL证书申请前置条件
vps-manager ssl-check

# 备份配置
vps-manager backup

# 代理管理工具
vps-manager proxy
# 或者直接使用
proxy-manager
```

## 🔐 SSL 证书管理

### 自动续期功能

脚本提供了完整的 SSL 证书自动续期功能：

- **自动检查**：每天凌晨 2 点自动检查证书有效期
- **智能续期**：证书剩余有效期 ≤ 30 天时自动续期
- **多域名支持**：支持主域名和子域名的证书管理
- **失败处理**：续期失败时的错误处理和通知
- **日志记录**：完整的续期日志记录

### SSL 管理命令

```bash
# 检查SSL证书状态
vps-manager ssl-status
# 显示所有证书的过期时间和状态

# 检查SSL证书申请前置条件
vps-manager ssl-check
# 检查域名解析、端口可用性、防火墙设置等

# 手动续期所有证书
vps-manager ssl-renew
# 立即续期所有即将过期的证书

# 查看续期日志
tail -f /var/log/ssl-renew.log
# 查看SSL证书续期的详细日志
```

### 前置条件检查

脚本在申请 SSL 证书前会自动检查以下条件：

1. **域名验证**：格式验证、DNS 解析检查
2. **网络检查**：外网连接、Let's Encrypt 服务器可达性
3. **端口检查**：80/443 端口可用性
4. **防火墙检查**：UFW/firewalld 配置
5. **工具检查**：openssl、curl、socat 等必要工具
6. **系统检查**：磁盘空间、acme.sh 安装状态

### 独立检查工具

```bash
# 检查系统环境（不检查特定域名）
./ssl-check.sh

# 检查特定域名的前置条件
./ssl-check.sh example.com

# 查看帮助信息
./ssl-check.sh --help
```

### 证书存储位置

```
/etc/nginx/ssl/
├── example.com.crt      # 主域名证书
├── example.com.key      # 主域名私钥
├── api.example.com.crt  # 子域名证书
└── api.example.com.key  # 子域名私钥
```

## 🔄 后续代理管理

### 代理管理工具功能

脚本提供了强大的代理管理工具，支持后续添加、删除和管理代理配置：

```bash
# 启动代理管理工具
proxy-manager
```

**主要功能：**

- ✅ **添加子域名代理** - 动态添加新的子域名代理配置
- ✅ **添加路径代理** - 动态添加新的路径代理配置
- ✅ **查看现有配置** - 显示所有当前的代理配置
- ✅ **删除代理配置** - 选择性删除不需要的代理配置
- ✅ **重新生成配置** - 重新生成所有代理配置文件
- ✅ **测试配置** - 测试 Nginx 配置和服务状态
- ✅ **备份/恢复** - 备份和恢复代理配置

### 使用示例

```bash
# 添加新的API子域名
proxy-manager
# 选择: 1 (添加子域名代理)
# 输入: api-v2
# 输入: 127.0.0.1:3001
# 选择: Y (启用SSL)
# 选择: Y (支持WebSocket)

# 添加新的管理路径
proxy-manager
# 选择: 2 (添加路径代理)
# 输入: /admin-v2
# 输入: 127.0.0.1:8081
# 选择: Y (支持WebSocket)
# 选择: N (不移除前缀)
```

## 📁 目录结构

```
/etc/nginx/
├── nginx.conf              # 主配置文件（高性能优化）
├── sites-available/        # 站点配置文件
│   ├── default            # 默认站点
│   └── [subdomain]        # 子域名配置
├── sites-enabled/         # 启用的站点（符号链接）
└── ssl/                   # SSL证书目录

/usr/local/x-ui/          # X-UI安装目录
/root/.acme.sh/           # acme.sh证书管理
/root/vps-init/           # 脚本目录
├── vps_setup.log         # 安装日志
├── ssl-check.sh          # SSL前置条件检查脚本
└── SSL_MANAGEMENT.md     # SSL管理文档
```

## ⚙️ 配置说明

### Nginx 高性能配置

脚本会根据您的 VPS 配置自动优化 Nginx：

- **Worker 进程数**: 自动设置为 CPU 核心数
- **连接数**: 根据内存大小自动计算
- **Gzip 压缩**: 启用对常见文件类型的压缩
- **安全头**: 自动添加安全相关的 HTTP 头
- **HTTP/2**: 在 HTTPS 站点启用 HTTP/2 支持

### 系统优化

- **网络优化**: TCP 参数优化、BBR 拥塞控制
- **内存优化**: 调整 swappiness 和 dirty ratio
- **文件描述符**: 提高系统文件描述符限制

## 🔒 安全特性

### 自动安全配置

- 隐藏 Nginx 版本号
- 添加安全 HTTP 头
- 配置防火墙规则
- 禁止访问隐藏文件

### SSL/TLS 配置

- 使用强加密套件
- 启用 HSTS
- 自动证书续期

## 📊 性能监控

### 查看性能指标

```bash
# 查看Nginx状态
systemctl status nginx

# 查看连接数
ss -tuln | grep :80
ss -tuln | grep :443

# 查看系统资源
htop
```

### 日志分析

```bash
# 查看访问日志
tail -f /var/log/nginx/access.log

# 查看错误日志
tail -f /var/log/nginx/error.log
```

## 🚨 故障排除

### 常见问题

1. **SSL 证书申请失败**

   ```bash
   # 检查SSL申请前置条件
   vps-manager ssl-check
   # 或
   ./ssl-check.sh your-domain.com

   # 检查域名解析
   nslookup your-domain.com
   dig your-domain.com

   # 检查端口占用
   netstat -tlnp | grep :80
   netstat -tlnp | grep :443

   # 手动申请证书
   /root/.acme.sh/acme.sh --issue -d your-domain.com --standalone
   ```

2. **SSL 证书续期失败**

   ```bash
   # 查看续期日志
   tail -f /var/log/ssl-renew.log

   # 检查证书状态
   vps-manager ssl-status

   # 手动续期
   vps-manager ssl-renew

   # 检查acme.sh状态
   /root/.acme.sh/acme.sh --list
   ```

3. **Nginx 配置错误**

   ```bash
   # 测试配置
   nginx -t

   # 查看详细错误
   journalctl -u nginx -f
   ```

4. **X-UI 无法访问**

   ```bash
   # 检查服务状态
   systemctl status x-ui

   # 检查端口
   netstat -tuln | grep 54321
   ```

### 日志文件

- 安装日志: `/root/vps-init/vps_setup.log`
- Nginx 日志: `/var/log/nginx/`
- SSL 续期日志: `/var/log/ssl-renew.log`
- SSL 检查日志: `/var/log/ssl-check.log`
- 系统日志: `/var/log/syslog`

## 🔄 更新维护

### 定期维护任务

```bash
# 更新系统包
apt update && apt upgrade -y  # Ubuntu/Debian
yum update -y                 # CentOS/RHEL

# 检查SSL证书状态
vps-manager ssl-status

# 更新SSL证书
vps-manager ssl-renew

# 备份配置
vps-manager backup
```

### 监控建议

- 定期检查磁盘空间
- 监控内存和 CPU 使用率
- 检查 SSL 证书有效期（使用 `vps-manager ssl-status`）
- 监控 SSL 续期日志（`tail -f /var/log/ssl-renew.log`）
- 查看错误日志
- 定期运行 SSL 前置条件检查（`vps-manager ssl-check`）

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如果您遇到问题或有建议，请：

1. 查看 [故障排除](#故障排除) 部分
2. 搜索现有的 [Issues](../../issues)
3. 创建新的 Issue 并详细描述问题

---

**注意**: 此脚本会修改系统配置，请在测试环境中先验证，生产环境使用前请做好备份。
