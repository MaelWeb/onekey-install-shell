# SSL 证书自动续期管理指南

## 概述

本 VPS 初始化脚本已集成完整的 SSL 证书自动续期功能，支持 Let's Encrypt 证书的自动申请、安装和续期。脚本包含全面的前置条件检查，确保证书申请的成功率。

## 功能特性

### ✅ 已实现功能

1. **前置条件检查**：全面的 SSL 证书申请前置条件检查
2. **自动证书申请**：使用 acme.sh 自动申请 Let's Encrypt 证书
3. **自动续期**：每天凌晨 2 点自动检查并续期即将过期的证书
4. **多域名支持**：支持主域名和子域名的证书管理
5. **智能检测**：自动检测 nginx 配置中的域名并管理对应证书
6. **状态监控**：提供证书状态检查工具
7. **日志记录**：完整的续期日志记录
8. **失败处理**：续期失败时的错误处理和通知

### 🔧 管理工具

#### 1. 证书状态检查

```bash
# 检查所有SSL证书状态
vps-manager ssl-status

# 或直接运行
/usr/local/bin/ssl-status.sh
```

#### 2. 手动续期

```bash
# 手动续期所有证书
vps-manager ssl-renew

# 或使用acme.sh直接续期
/root/.acme.sh/acme.sh --renew-all
```

#### 3. 查看续期日志

```bash
# 查看SSL续期日志
tail -f /var/log/ssl-renew.log

# 查看系统日志中的SSL相关信息
journalctl -t "SSL-Renewal" -f
```

## SSL 证书申请前置条件

### 自动检查项目

脚本会在申请 SSL 证书前自动检查以下前置条件：

1. **域名格式验证**：确保域名格式正确
2. **DNS 解析检查**：验证域名是否正确解析到服务器 IP
3. **端口可用性**：
   - 80 端口：acme.sh 进行域名验证必需
   - 443 端口：HTTPS 访问必需
4. **防火墙设置**：确保 80 和 443 端口未被阻止
5. **网络连接**：检查外网连接和 Let's Encrypt 服务器可达性
6. **必要工具**：检查 openssl、curl、socat 等工具是否安装
7. **磁盘空间**：确保有足够空间存储证书
8. **证书状态**：检查是否已存在有效证书
9. **域名可访问性**：验证域名是否可以通过 HTTP 访问

### 检查结果处理

- **通过检查**：继续申请证书
- **警告项目**：提示用户确认是否继续
- **错误项目**：停止申请并提示用户修复

## 自动续期机制

### 续期策略

- **检查频率**：每天凌晨 2 点自动检查
- **续期阈值**：证书剩余有效期 ≤ 30 天时自动续期
- **续期方式**：使用 standalone 模式（临时停止 nginx）
- **重载服务**：续期成功后自动重载 nginx 配置

### 续期流程

1. **检查证书状态**：计算证书剩余有效期
2. **判断是否需要续期**：剩余天数 ≤ 30 天时触发续期
3. **停止 nginx 服务**：释放 80 端口用于域名验证
4. **执行续期**：使用 acme.sh 进行证书续期
5. **重新安装证书**：将新证书安装到 nginx 配置目录
6. **重启 nginx 服务**：应用新证书
7. **记录日志**：记录续期结果
8. **发送通知**：可配置续期结果通知

### 支持的域名类型

- **主域名**：example.com
- **子域名**：api.example.com, www.example.com
- **通配符域名**：\*.example.com（需要 DNS 验证）

## 配置文件

### 证书存储位置

```
/etc/nginx/ssl/
├── example.com.crt      # 主域名证书
├── example.com.key      # 主域名私钥
├── api.example.com.crt  # 子域名证书
└── api.example.com.key  # 子域名私钥
```

### 脚本位置

```
/usr/local/bin/
├── ssl-renew.sh         # 自动续期脚本
└── ssl-status.sh        # 状态检查脚本
```

### 日志文件

```
/var/log/ssl-renew.log   # 续期日志
```

## 故障排除

### 常见问题

#### 1. 证书申请失败

```bash
# 检查域名DNS解析
dig example.com
nslookup example.com

# 检查80端口是否被占用
netstat -tlnp | grep :80

# 检查防火墙设置
ufw status  # Ubuntu/Debian
firewall-cmd --list-ports  # CentOS/RHEL

# 检查网络连接
ping 8.8.8.8
curl -I https://acme-v02.api.letsencrypt.org/directory

# 检查必要工具
which openssl curl socat
```

#### 2. 续期失败

```bash
# 检查续期日志
tail -f /var/log/ssl-renew.log

# 检查acme.sh状态
/root/.acme.sh/acme.sh --list

# 手动测试续期
/root/.acme.sh/acme.sh --renew -d example.com --standalone
```

#### 2. 证书过期

```bash
# 检查证书状态
openssl x509 -in /etc/nginx/ssl/example.com.crt -noout -dates

# 强制重新申请证书
/root/.acme.sh/acme.sh --force --issue -d example.com --standalone
```

#### 3. nginx 配置错误

```bash
# 测试nginx配置
nginx -t

# 检查nginx错误日志
tail -f /var/log/nginx/error.log
```

### 手动操作

#### 重新申请证书

```bash
# 停止nginx
systemctl stop nginx

# 重新申请证书
/root/.acme.sh/acme.sh --force --issue -d example.com --standalone

# 重新安装证书
/root/.acme.sh/acme.sh --installcert -d example.com \
  --key-file /etc/nginx/ssl/example.com.key \
  --fullchain-file /etc/nginx/ssl/example.com.crt \
  --reloadcmd "systemctl reload nginx"

# 启动nginx
systemctl start nginx
```

#### 添加新域名证书

```bash
# 申请新域名证书
/root/.acme.sh/acme.sh --issue -d new.example.com --standalone

# 安装证书
/root/.acme.sh/acme.sh --installcert -d new.example.com \
  --key-file /etc/nginx/ssl/new.example.com.key \
  --fullchain-file /etc/nginx/ssl/new.example.com.crt \
  --reloadcmd "systemctl reload nginx"
```

## 监控和通知

### 系统监控

```bash
# 设置证书过期监控（添加到cron）
# 每天检查证书状态，如果30天内过期则发送通知
0 8 * * * /usr/local/bin/ssl-status.sh | grep -q "⚠️" && echo "SSL证书即将过期" | mail -s "SSL证书警告" admin@example.com
```

### 通知配置

可以在 `/usr/local/bin/ssl-renew.sh` 中的 `send_notification` 函数添加：

- 邮件通知
- 钉钉通知
- 企业微信通知
- Telegram 通知
- 短信通知

## 安全建议

1. **定期备份**：定期备份 SSL 证书和私钥
2. **权限控制**：确保证书文件权限正确（600）
3. **监控告警**：设置证书过期监控告警
4. **日志轮转**：配置日志轮转避免日志文件过大
5. **更新 acme.sh**：定期更新 acme.sh 到最新版本

## 最佳实践

1. **域名验证**：确保域名 DNS 解析正确指向服务器
2. **防火墙配置**：确保 80 和 443 端口开放
3. **备份策略**：定期备份证书和 nginx 配置
4. **测试环境**：在生产环境使用前先在测试环境验证
5. **文档记录**：记录所有证书的申请和续期情况

## 联系支持

如果遇到 SSL 证书相关问题，请：

1. 查看相关日志文件
2. 检查域名 DNS 解析
3. 验证服务器网络连接
4. 参考 acme.sh 官方文档
