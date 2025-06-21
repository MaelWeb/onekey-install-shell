# 腾讯云自动购买脚本使用说明

## 🚀 快速使用

### 1. 首次使用（选择套餐）

```bash
# 启动管理工具
node manage.js

# 选择 "1. 选择套餐 (交互式)"
# 按照提示选择你想要的套餐
# 选择 "y" 保存到配置文件
```

### 2. 启动自动购买

```bash
# 方法一：使用管理工具
node manage.js
# 选择 "2. 启动自动购买 (PM2)"

# 方法二：直接使用 PM2
pm2 start ecosystem.config.js
```

### 3. 查看状态和日志

```bash
# 使用管理工具
node manage.js
# 选择 "5. 查看运行状态" 或 "6. 查看日志"

# 或直接使用 PM2 命令
pm2 status
pm2 logs tencent-auto-buy
```

### 4. 停止服务

```bash
# 使用管理工具
node manage.js
# 选择 "3. 停止自动购买 (PM2)"

# 或直接使用 PM2 命令
pm2 stop tencent-auto-buy
```

## 📋 常用命令

| 功能 | 管理工具 | PM2 命令 |
|------|----------|----------|
| 选择套餐 | `node manage.js` → 选择 1 | - |
| 启动服务 | `node manage.js` → 选择 2 | `pm2 start ecosystem.config.js` |
| 停止服务 | `node manage.js` → 选择 3 | `pm2 stop tencent-auto-buy` |
| 重启服务 | `node manage.js` → 选择 4 | `pm2 restart tencent-auto-buy` |
| 查看状态 | `node manage.js` → 选择 5 | `pm2 status` |
| 查看日志 | `node manage.js` → 选择 6 | `pm2 logs tencent-auto-buy` |
| 查看套餐 | `node manage.js` → 选择 7 | - |

## ⚠️ 注意事项

1. **首次使用必须先选择套餐**：PM2 运行时无法进行交互式选择
2. **确保配置文件正确**：检查 `config.json` 中的腾讯云凭证
3. **监控日志**：定期查看日志了解运行状态
4. **合理设置轮询间隔**：避免过于频繁的 API 调用

## 🔧 故障排除

### PM2 运行时没有交互界面
- 这是正常现象，PM2 在后台运行
- 使用 `node manage.js` 进行交互式操作
- 或直接编辑 `config.json` 文件

### PM2 启动时报 readline 错误
- 错误信息：`Error [ERR_USE_AFTER_CLOSE]: readline was closed`
- **解决方案**：
  1. 确保已经通过管理工具选择了套餐并保存到配置文件
  2. 检查 `ecosystem.config.js` 中 `INTERACTIVE_MODE: 'false'` 设置正确
  3. 重启 PM2 服务：
     ```bash
     pm2 delete tencent-auto-buy
     pm2 start ecosystem.config.js
     ```
  4. 如果问题持续，可以运行测试脚本：
     ```bash
     node test-pm2.js
     ```

### 无法连接到腾讯云
- 检查 `secretId` 和 `secretKey` 是否正确
- 确认网络连接正常
- 检查腾讯云 API 配额

### 套餐选择失败
- 确认腾讯云凭证有效
- 检查地域设置是否正确
- 查看错误日志获取详细信息 