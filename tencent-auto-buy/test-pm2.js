#!/usr/bin/env node

/**
 * @fileoverview PM2 环境测试脚本
 * @description 测试在 PM2 环境下的非交互模式运行
 */

// 模拟 PM2 环境
process.env.INTERACTIVE_MODE = 'false';

const { AutoBuyManager, TencentCloudClient, ConfigManager, Logger } = require('./auto_buy_tencent.js');

async function testPM2Mode() {
  console.log('🧪 开始测试 PM2 环境下的非交互模式...');
  
  try {
    // 加载配置
    const configManager = new ConfigManager();
    const config = await configManager.loadConfig();
    console.log('✅ 配置加载成功');
    console.log(`交互模式: ${config.interactiveMode}`);
    console.log(`目标套餐: ${config.bundleId}`);

    // 验证配置
    if (config.secretId === 'YOUR_SECRET_ID' || config.secretKey === 'YOUR_SECRET_KEY') {
      console.log('❌ 请先在配置文件中设置正确的腾讯云凭证');
      process.exit(1);
    }

    // 初始化客户端
    const client = new TencentCloudClient(config);
    console.log('✅ 腾讯云客户端初始化成功');

    // 初始化日志
    const logger = new Logger('./test-pm2.log');
    console.log('✅ 日志系统初始化成功');

    // 初始化管理器（不传入 CLI）
    const manager = new AutoBuyManager(config, client, logger, null);
    console.log('✅ 自动购买管理器初始化成功');

    // 测试启动流程（不实际开始轮询）
    console.log('🧪 测试启动流程...');
    
    // 验证凭证
    await client.validateCredentials();
    console.log('✅ 凭证验证成功');

    // 检查是否跳过交互式操作
    if (!config.interactiveMode) {
      console.log('✅ 非交互模式，跳过交互式操作');
    } else {
      console.log('⚠️  交互模式，可能会尝试交互式操作');
    }

    console.log('🎉 PM2 环境测试完成！');
    console.log('现在可以使用 PM2 启动服务了：');
    console.log('  pm2 start ecosystem.config.js');

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    console.error('错误堆栈:', error.stack);
    process.exit(1);
  }
}

// 运行测试
if (require.main === module) {
  testPM2Mode().catch(error => {
    console.error('测试异常退出:', error.message);
    process.exit(1);
  });
}

module.exports = { testPM2Mode }; 