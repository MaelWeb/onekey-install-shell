# VPS 自动化配置脚本使用指南

## 🚀 快速开始

### 方法一：一键安装（推荐）

```bash
# 下载并执行快速安装脚本
curl -fsSL https://raw.githubusercontent.com/MaelWeb/onekey-install-shell/main/vps-init/quick-install.sh | bash

# 或者使用wget
wget -qO- https://raw.githubusercontent.com/MaelWeb/onekey-install-shell/main/vps-init/quick-install.sh | bash
```

### 方法二：手动安装

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/MaelWeb/onekey-install-shell/main/vps-init/init.sh

# 2. 设置执行权限
chmod +x init.sh

# 3. 运行脚本
sudo ./init.sh
```

## 📋 使用场景示例

### 场景 1：基础 VPS 配置

适用于新购买的 VPS，需要快速配置基础服务。

```bash
# 执行完整安装
sudo ./init.sh

# 交互式配置示例：
# 域名: example.com
# 反向代理: 不添加
# 结果: 获得一个基础的Nginx + X-UI配置
```

### 场景 2：Web 应用部署

适用于需要部署多个 Web 应用的 VPS。

```bash
sudo ./init.sh

# 交互式配置示例：
# 域名: myapp.com
# 反向代理配置:
#   子域名代理:
#     - api.myapp.com -> 127.0.0.1:3000 (API服务)
#     - admin.myapp.com -> 127.0.0.1:8080 (管理后台)
#   路径代理:
#     - myapp.com/api -> 127.0.0.1:3000 (API服务)
#     - myapp.com/admin -> 127.0.0.1:8080 (管理后台)
#     - myapp.com/static -> 127.0.0.1:4000 (静态资源)
```

### 场景 3：开发环境配置

适用于开发团队的测试环境。

```bash
sudo ./init.sh

# 交互式配置示例：
# 域名: dev.example.com
# 反向代理配置:
#   子域名代理:
#     - api.dev.example.com -> 127.0.0.1:8000 (开发API)
#     - docs.dev.example.com -> 127.0.0.1:3001 (文档服务)
#   路径代理:
#     - dev.example.com/api -> 127.0.0.1:8000 (开发API)
#     - dev.example.com/docs -> 127.0.0.1:3001 (文档服务)
#     - dev.example.com/monitor -> 127.0.0.1:9090 (监控面板)
```

### 场景 4：单域名多服务配置

适用于只有一个域名但需要部署多个服务的场景。

```bash
sudo ./init.sh

# 交互式配置示例：
# 域名: myapp.com
# 路径代理配置:
#   - myapp.com/api -> 127.0.0.1:3000 (API服务)
#   - myapp.com/admin -> 127.0.0.1:8080 (管理后台)
#   - myapp.com/static -> 127.0.0.1:4000 (静态资源)
#   - myapp.com/ws -> 127.0.0.1:5000 (WebSocket服务)
```

## 🔧 配置示例

### Nginx 配置示例

脚本会自动生成高性能的 Nginx 配置：

```nginx
# 主配置文件 (/etc/nginx/nginx.conf)
user nginx;
worker_processes 4;  # 根据CPU核心数自动设置
worker_connections 2048;  # 根据内存自动计算

events {
    use epoll;
    worker_connections 2048;
    multi_accept on;
}

http {
    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    # 包含站点配置
    include /etc/nginx/sites-enabled/*;
}
```

### 反向代理配置示例

#### 子域名代理配置

```nginx
# 子域名配置 (/etc/nginx/sites-available/api)
server {
    listen 80;
    server_name api.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### 路径代理配置

```nginx
# 路径代理配置 (/etc/nginx/sites-available/path-proxy)
server {
    listen 80;
    server_name example.com;

    # API路径代理
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 管理后台路径代理（移除前缀）
    location /admin {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 默认站点
    location / {
        root /var/www/html;
        index index.html index.htm;
        try_files $uri $uri/ =404;
    }
}
```

## 🛠️ 管理操作

### 服务管理

```bash
# 查看所有服务状态
vps-manager status

# 重启所有服务
vps-manager restart

# 查看实时日志
vps-manager logs

# 更新SSL证书
vps-manager ssl-renew

# 备份配置
vps-manager backup
```

### 手动管理

```bash
# Nginx管理
systemctl status nginx
systemctl restart nginx
nginx -t  # 测试配置

# X-UI管理
systemctl status x-ui
systemctl restart x-ui

# 查看端口占用
netstat -tuln | grep :80
netstat -tuln | grep :443
netstat -tuln | grep :54321
```

## 🔍 故障排除

### 常见问题及解决方案

#### 1. SSL 证书申请失败

**问题**: 无法申请 Let's Encrypt 证书

**解决方案**:

```bash
# 检查域名解析
nslookup your-domain.com

# 检查80端口是否被占用
netstat -tuln | grep :80

# 手动申请证书
/root/.acme.sh/acme.sh --issue -d your-domain.com --standalone

# 查看acme.sh日志
tail -f /root/.acme.sh/acme.sh.log
```

#### 2. Nginx 配置错误

**问题**: Nginx 无法启动或重载

**解决方案**:

```bash
# 测试配置语法
nginx -t

# 查看详细错误
journalctl -u nginx -f

# 检查配置文件
ls -la /etc/nginx/sites-enabled/

# 临时禁用问题站点
rm /etc/nginx/sites-enabled/problem-site
nginx -s reload
```

#### 3. X-UI 无法访问

**问题**: 无法访问 X-UI 面板

**解决方案**:

```bash
# 检查服务状态
systemctl status x-ui

# 检查端口
netstat -tuln | grep 54321

# 检查防火墙
ufw status  # Ubuntu/Debian
firewall-cmd --list-all  # CentOS/RHEL

# 查看X-UI日志
journalctl -u x-ui -f
```

#### 4. 反向代理不工作

**问题**: 反向代理无法访问后端服务

**解决方案**:

```bash
# 检查后端服务是否运行
netstat -tuln | grep :3000

# 测试后端服务
curl http://127.0.0.1:3000

# 检查Nginx配置
nginx -t

# 查看Nginx错误日志
tail -f /var/log/nginx/error.log
```

#### 5. 路径代理配置问题

**问题**: 路径代理无法正常工作

**解决方案**:

```bash
# 检查路径代理配置
cat /etc/nginx/sites-available/path-proxy

# 测试路径访问
curl http://your-domain.com/api
curl http://your-domain.com/admin

# 检查路径匹配顺序
# 确保更具体的路径在前面

# 查看访问日志
tail -f /var/log/nginx/access.log | grep "your-domain.com"
```

## 📊 性能监控

### 系统监控

```bash
# 查看系统资源
htop
free -h
df -h

# 查看网络连接
ss -tuln
netstat -i

# 查看进程
ps aux | grep nginx
ps aux | grep x-ui
```

### Nginx 监控

```bash
# 查看访问统计
tail -f /var/log/nginx/access.log | grep -v "health"

# 查看错误统计
tail -f /var/log/nginx/error.log

# 查看连接数
ss -tuln | grep :80 | wc -l
ss -tuln | grep :443 | wc -l
```

### 日志分析

```bash
# 统计访问量
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10

# 统计错误码
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr

# 统计访问时间
awk '{print $4}' /var/log/nginx/access.log | cut -d: -f2 | sort | uniq -c
```

## 🔄 维护操作

### 定期维护

```bash
# 每日维护脚本示例
#!/bin/bash

# 更新系统包
apt update && apt upgrade -y

# 更新SSL证书
/root/.acme.sh/acme.sh --renew-all

# 重启Nginx
systemctl reload nginx

# 备份配置
vps-manager backup

# 清理日志（保留7天）
find /var/log/nginx -name "*.log" -mtime +7 -delete
```

### 后续代理管理

安装完成后，您可以使用代理管理工具进行后续配置：

```bash
# 启动代理管理工具
proxy-manager

# 或者通过vps-manager启动
vps-manager proxy
```

**代理管理工具功能：**

1. **添加子域名代理**

   - 动态添加新的子域名代理配置
   - 支持 SSL 和 WebSocket 配置
   - 自动生成 Nginx 配置文件

2. **添加路径代理**

   - 动态添加新的路径代理配置
   - 支持路径前缀移除选项
   - 自动更新现有配置文件

3. **查看现有配置**

   - 显示所有子域名代理
   - 显示所有路径代理
   - 显示启用的站点列表

4. **删除代理配置**

   - 选择性删除子域名代理
   - 选择性删除路径代理
   - 自动清理配置文件

5. **配置管理**
   - 重新生成所有代理配置
   - 测试 Nginx 配置
   - 备份和恢复配置

**使用场景示例：**

```bash
# 场景1: 添加新的API版本
proxy-manager
# 选择: 1 (添加子域名代理)
# 子域名: api-v2
# 后端: 127.0.0.1:3001
# SSL: Y
# WebSocket: Y

# 场景2: 添加新的管理界面
proxy-manager
# 选择: 2 (添加路径代理)
# 路径: /admin-v2
# 后端: 127.0.0.1:8081
# WebSocket: N
# 移除前缀: N

# 场景3: 查看当前配置
proxy-manager
# 选择: 3 (查看现有代理配置)

# 场景4: 删除不需要的配置
proxy-manager
# 选择: 4 (删除代理配置)
# 选择: 1 (删除子域名代理)
# 选择要删除的配置编号
```

### 备份策略

```bash
# 创建备份脚本
cat > /root/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# 备份Nginx配置
tar -czf "$BACKUP_DIR/nginx_$DATE.tar.gz" /etc/nginx

# 备份X-UI配置
tar -czf "$BACKUP_DIR/xui_$DATE.tar.gz" /usr/local/x-ui

# 备份SSL证书
tar -czf "$BACKUP_DIR/ssl_$DATE.tar.gz" /root/.acme.sh

# 删除7天前的备份
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "备份完成: $BACKUP_DIR"
EOF

chmod +x /root/backup.sh

# 添加到crontab（每天凌晨2点执行）
echo "0 2 * * * /root/backup.sh" | crontab -
```

## 🎯 最佳实践

### 安全建议

1. **及时更新密码**

   ```bash
   # 修改X-UI面板密码
   # 登录面板后立即修改默认密码
   ```

2. **定期更新系统**

   ```bash
   # 设置自动更新
   apt install unattended-upgrades
   dpkg-reconfigure unattended-upgrades
   ```

3. **监控异常访问**
   ```bash
   # 查看异常IP访问
   awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -20
   ```

### 性能优化

1. **调整 Nginx 配置**

   ```bash
   # 根据服务器配置调整worker_processes
   # 编辑 /etc/nginx/nginx.conf
   ```

2. **启用 BBR 拥塞控制**

   ```bash
   # 检查BBR是否启用
   sysctl net.ipv4.tcp_congestion_control
   ```

3. **优化文件描述符**
   ```bash
   # 检查当前限制
   ulimit -n
   ```

### 监控告警

```bash
# 创建监控脚本
cat > /root/monitor.sh << 'EOF'
#!/bin/bash

# 检查服务状态
if ! systemctl is-active --quiet nginx; then
    echo "Nginx服务异常" | mail -s "服务告警" admin@example.com
fi

if ! systemctl is-active --quiet x-ui; then
    echo "X-UI服务异常" | mail -s "服务告警" admin@example.com
fi

# 检查磁盘空间
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "磁盘空间不足: ${DISK_USAGE}%" | mail -s "磁盘告警" admin@example.com
fi
EOF

chmod +x /root/monitor.sh

# 添加到crontab（每5分钟执行一次）
echo "*/5 * * * * /root/monitor.sh" | crontab -
```

## 📞 技术支持

如果您在使用过程中遇到问题：

1. 查看本文档的故障排除部分
2. 检查安装日志: `/root/vps-init/vps_setup.log`
3. 查看系统日志: `journalctl -xe`
4. 提交 Issue 到 GitHub 仓库

---

**注意**: 在生产环境使用前，请在测试环境中充分验证脚本的功能。
