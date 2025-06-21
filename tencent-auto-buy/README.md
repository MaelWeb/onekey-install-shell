# 腾讯云轻量应用服务器自动购买脚本

[![Node.js Version](https://img.shields.io/badge/node.js-%3E%3D14.0.0-brightgreen.svg)](https://nodejs.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

一个用于自动监控并购买腾讯云轻量应用服务器锐驰型套餐的 Node.js 脚本。

## ✨ 特性

- 🔄 **自动轮询**: 持续监控指定套餐的库存状态
- 🎯 **智能购买**: 检测到库存时自动下单
- 📝 **完整日志**: 控制台和文件双重日志记录
- ⚙️ **灵活配置**: 支持配置文件和环境变量
- 🛡️ **错误处理**: 完善的错误处理和重试机制
- 🚪 **优雅退出**: 支持 Ctrl+C 优雅退出
- 🔐 **安全凭证**: 支持环境变量配置敏感信息
- 🎮 **交互式选择**: 支持交互式套餐选择和配置保存
- 🔍 **自动监控库存**: 定期检查指定套餐的库存状态
- 📊 **价格显示**: 显示套餐价格信息
- 🚀 **PM2 支持**: 支持 PM2 进程管理
- 🛠️ **管理工具**: 提供统一的管理界面

## 📋 系统要求

- Node.js >= 14.0.0
- 腾讯云账号和 API 密钥
- PM2 (可选，用于进程管理)

## 🚀 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置凭证

#### 方法一：使用配置文件（推荐）

编辑 `config.json` 文件：

```json
{
  "secretId": "你的腾讯云SecretId",
  "secretKey": "你的腾讯云SecretKey",
  "region": "ap-hongkong",
  "bundleId": "bundle-razor-xxxx",
  "blueprintId": "lhbp-xxxx",
  "instanceNamePrefix": "auto-ruichi",
  "instanceCount": 1,
  "checkInterval": 10000,
  "maxRetries": 3,
  "exitAfterPurchase": false,
  "logFile": "./auto-buy.log",
  "interactiveMode": true
}
```

#### 方法二：使用环境变量

```bash
export TENCENT_SECRET_ID="你的腾讯云SecretId"
export TENCENT_SECRET_KEY="你的腾讯云SecretKey"
```

### 3. 使用管理工具（推荐）

```bash
node manage.js
```

管理工具提供以下功能：
- 选择套餐 (交互式)
- 启动自动购买 (PM2)
- 停止自动购买 (PM2)
- 重启自动购买 (PM2)
- 查看运行状态
- 查看日志
- 查看套餐列表

### 4. 直接运行脚本

```bash
npm start
```

或者直接运行：

```bash
node auto_buy_tencent.js
```

## 🛠️ 管理工具使用指南

### 启动管理工具

```bash
node manage.js
```

### 功能说明

1. **选择套餐 (交互式)**
   - 启动交互式套餐选择工具
   - 显示所有可用的锐驰型套餐
   - 支持保存选择到配置文件

2. **启动自动购买 (PM2)**
   - 使用 PM2 启动自动购买服务
   - 在后台持续运行
   - 自动重启和错误恢复

3. **停止自动购买 (PM2)**
   - 停止 PM2 管理的自动购买服务
   - 保留配置和日志

4. **重启自动购买 (PM2)**
   - 重启 PM2 管理的自动购买服务
   - 适用于配置更新后重启

5. **查看运行状态**
   - 显示 PM2 进程状态
   - 查看内存和 CPU 使用情况

6. **查看日志**
   - 显示最近的运行日志
   - 实时监控程序运行状态

7. **查看套餐列表**
   - 显示当前可用的套餐列表
   - 包含价格和库存状态

## 🎮 交互式功能

脚本支持交互式套餐选择，运行时会：

1. **显示当前配置**: 展示当前的配置信息
2. **查询套餐列表**: 获取所有可用的锐驰型套餐
3. **分类显示**: 将有库存和无库存的套餐分开显示
4. **用户选择**: 通过数字选择目标套餐
5. **保存选择**: 询问是否将选择保存到配置文件
6. **开始监控**: 询问是否立即开始监控

### 交互流程示例

```
📋 当前配置信息：
==================================================
地域: ap-hongkong
目标套餐: bundle-razor-xxxx
镜像ID: lhbp-xxxx
实例名称前缀: auto-ruichi
购买数量: 1
轮询间隔: 10000ms
最大重试次数: 3
购买后退出: 否
==================================================

📋 可用的锐驰型套餐列表：
================================================================================

✅ 有库存的套餐：
  1. bundle-razor-1c1g - 1核1GB - 带宽: 30Mbps - 状态: AVAILABLE
  2. bundle-razor-2c2g - 2核2GB - 带宽: 30Mbps - 状态: AVAILABLE

❌ 无库存的套餐：
  3. bundle-razor-4c4g - 4核4GB - 带宽: 30Mbps - 状态: SOLD_OUT

================================================================================

请选择套餐 (1-3)，或输入 0 退出: 2

✅ 已选择套餐: bundle-razor-2c2g - 2核2GB

是否将套餐 bundle-razor-2c2g 保存到配置文件？(y/N): y

✅ 套餐选择已保存到配置文件: bundle-razor-2c2g

是否立即开始监控该套餐的库存？(Y/n): Y

ℹ️ 开始轮询套餐 bundle-razor-2c2g 的库存情况...
```

## 🚀 PM2 使用指南

### 安装 PM2

```bash
npm install -g pm2
```

### 启动服务

```bash
# 使用管理工具启动
node manage.js
# 选择 "2. 启动自动购买 (PM2)"

# 或直接使用 PM2 命令
pm2 start ecosystem.config.js
```

### 查看状态

```bash
pm2 status
```

### 查看日志

```bash
pm2 logs tencent-auto-buy
```

### 停止服务

```bash
pm2 stop tencent-auto-buy
```

### 重启服务

```bash
pm2 restart tencent-auto-buy
```

### 删除服务

```bash
pm2 delete tencent-auto-buy
```

## ⚙️ 配置说明

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `secretId` | string | - | 腾讯云 Secret ID |
| `secretKey` | string | - | 腾讯云 Secret Key |
| `region` | string | `ap-hongkong` | 地域 |
| `bundleId` | string | `bundle-razor-xxxx` | 目标套餐 ID |
| `blueprintId` | string | `lhbp-xxxx` | 镜像 ID |
| `instanceNamePrefix` | string | `auto-ruichi` | 实例名称前缀 |
| `instanceCount` | number | `1` | 购买数量 |
| `checkInterval` | number | `10000` | 轮询间隔（毫秒） |
| `maxRetries` | number | `3` | 最大重试次数 |
| `exitAfterPurchase` | boolean | `false` | 购买后是否退出 |
| `logFile` | string | `./auto-buy.log` | 日志文件路径 |
| `interactiveMode` | boolean | `true` | 是否启用交互模式 |

## 🔧 获取配置信息

### 获取套餐 ID

1. 登录腾讯云控制台
2. 进入轻量应用服务器
3. 创建实例时查看套餐列表
4. 复制目标套餐的 ID

### 获取镜像 ID

1. 在轻量应用服务器控制台
2. 进入镜像管理
3. 复制目标镜像的 ID

## 📊 日志格式

脚本会同时输出到控制台和日志文件：

### 控制台输出
```
ℹ️ [2025-01-22T10:30:00.000Z] INFO: 正在验证腾讯云凭证...
✅ [2025-01-22T10:30:01.000Z] SUCCESS: 凭证验证成功
```

### 日志文件格式（JSON）
```json
{
  "timestamp": "2025-01-22T10:30:00.000Z",
  "level": "info",
  "message": "正在验证腾讯云凭证...",
  "data": null
}
```

## 🛠️ 高级用法

### 禁用交互模式

在配置文件中设置 `"interactiveMode": false`，脚本将直接使用配置文件中的套餐 ID 开始监控。

### 作为模块使用

```javascript
const { AutoBuyManager, TencentCloudClient, ConfigManager, Logger } = require('./auto_buy_tencent.js');

async function customAutoBuy() {
  const config = {
    secretId: 'your-secret-id',
    secretKey: 'your-secret-key',
    interactiveMode: false, // 禁用交互模式
    // ... 其他配置
  };
  
  const logger = new Logger('./custom.log');
  const client = new TencentCloudClient(config);
  const manager = new AutoBuyManager(config, client, logger);
  
  await manager.start();
}
```

### 自定义轮询逻辑

```javascript
class CustomAutoBuyManager extends AutoBuyManager {
  async startPolling() {
    while (this.isRunning) {
      // 自定义轮询逻辑
      const isAvailable = await this.client.isInStock(this.config.bundleId);
      
      if (isAvailable) {
        // 自定义购买逻辑
        await this.attemptPurchase();
      }
      
      await this.sleep(this.config.checkInterval);
    }
  }
}
```

### 批量套餐监控

```javascript
class BatchAutoBuyManager extends AutoBuyManager {
  async startPolling() {
    const targetBundles = ['bundle-1', 'bundle-2', 'bundle-3'];
    
    while (this.isRunning) {
      for (const bundleId of targetBundles) {
        const isAvailable = await this.client.isInStock(bundleId);
        if (isAvailable) {
          await this.logger.info(`套餐 ${bundleId} 有库存，尝试购买`);
          await this.attemptPurchase(bundleId);
        }
      }
      await this.sleep(this.config.checkInterval);
    }
  }
}
```

## 🔒 安全注意事项

1. **保护凭证**: 不要将 `config.json` 提交到版本控制系统
2. **环境变量**: 生产环境建议使用环境变量配置敏感信息
3. **权限控制**: 确保 API 密钥具有最小必要权限
4. **日志安全**: 定期清理日志文件，避免泄露敏感信息

## 🐛 故障排除

### 常见错误

1. **AuthFailure**: 检查 SecretId 和 SecretKey 是否正确
2. **InvalidParameter**: 检查 bundleId 和 blueprintId 是否有效
3. **InsufficientBalance**: 确保账户余额充足

### 调试模式

```bash
npm run dev
```

### 禁用交互模式进行自动化

```bash
# 修改配置文件中的 interactiveMode 为 false
# 或者设置环境变量
export INTERACTIVE_MODE=false
node auto_buy_tencent.js
```

## 📝 更新日志

### v2.1.0
- 添加交互式套餐选择功能
- 支持套餐选择保存到配置文件
- 改进套餐信息显示（包含带宽信息）
- 添加用户友好的交互流程

### v2.0.0
- 重构为面向对象架构
- 添加完整的错误处理
- 实现配置管理系统
- 添加日志系统
- 支持优雅退出

### v1.0.0
- 基础自动购买功能

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 📞 支持

如有问题，请通过以下方式联系：

- 提交 [Issue](https://github.com/your-username/tencent-auto-buy/issues)
- 发送邮件至：edenliang@tencent.com

---

**注意**: 使用本脚本前请确保了解腾讯云的服务条款和计费规则。

## 🚀 PM2 使用说明

### 安装 PM2

```bash
npm install -g pm2
```

### 使用 PM2 启动

```bash
# 启动应用
npm run pm2:start

# 查看状态
npm run pm2:status

# 查看日志
npm run pm2:logs

# 重启应用
npm run pm2:restart

# 停止应用
npm run pm2:stop
```

或者直接使用 PM2 命令：

```bash
# 启动
pm2 start ecosystem.config.js

# 查看状态
pm2 status

# 查看日志
pm2 logs tencent-auto-buy

# 重启
pm2 restart tencent-auto-buy

# 停止
pm2 stop tencent-auto-buy
``` 