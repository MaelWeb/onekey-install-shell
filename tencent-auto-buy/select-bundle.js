#!/usr/bin/env node

/**
 * @fileoverview 腾讯云轻量应用服务器套餐选择工具
 * @author edenliang edenliang@tencent.com
 * @version 1.0.0
 * @description 交互式选择套餐并保存到配置文件
 */

const { AutoBuyManager, TencentCloudClient, ConfigManager, Logger, InteractiveCLI } = require('./auto_buy_tencent.js');
const readline = require('readline');

// ========== 套餐选择器 ==========
class BundleSelector {
  /**
   * @param {string} configPath - 配置文件路径
   */
  constructor(configPath = './config.json') {
    this.configPath = configPath;
  }

  /**
   * 启动套餐选择流程
   */
  async start() {
    const logger = new Logger('./bundle-select.log');
    
    try {
      // 加载配置
      await logger.info('正在加载配置文件...');
      const configManager = new ConfigManager(this.configPath);
      const config = await configManager.loadConfig();
      await logger.success('配置文件加载成功');

      // 验证必要配置
      if (config.secretId === 'YOUR_SECRET_ID' || config.secretKey === 'YOUR_SECRET_KEY') {
        await logger.error('请先在配置文件中设置正确的腾讯云凭证');
        process.exit(1);
      }

      // 初始化客户端
      await logger.info('正在初始化腾讯云客户端...');
      const client = new TencentCloudClient(config);
      await logger.success('腾讯云客户端初始化成功');
      
      // 初始化交互式命令行工具
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });
      const cli = new InteractiveCLI(rl);
      
      // 查询套餐列表
      await logger.info('正在查询锐驰型套餐列表...');
      const bundles = await client.listRazorBundles();
      await logger.info(`找到 ${bundles.length} 个锐驰型套餐`);
      
      // 显示当前配置
      cli.showCurrentConfig(config);
      
      // 用户选择套餐
      const selectedBundleId = await cli.selectBundle(bundles);
      
      // 询问是否保存选择
      const shouldSave = await cli.confirmSaveSelection(selectedBundleId);
      if (shouldSave) {
        await configManager.updateBundleId(selectedBundleId);
        await logger.success(`套餐选择已保存到配置文件: ${selectedBundleId}`);
        console.log(`\n✅ 套餐 ${selectedBundleId} 已保存到配置文件`);
        console.log('现在可以使用 PM2 启动自动购买程序了：');
        console.log('  pm2 start ecosystem.config.js');
      } else {
        console.log(`\n⚠️  套餐选择未保存，下次运行仍将使用配置文件中的套餐`);
      }
      
      rl.close();
      await logger.info('套餐选择流程完成');
      
    } catch (error) {
      if (error.message === '用户取消选择') {
        await logger.info('用户取消选择，程序退出');
        process.exit(0);
      }
      
      console.error('套餐选择失败:', error.message);
      await logger.error('套餐选择失败', {
        message: error.message,
        stack: error.stack
      });
      process.exit(1);
    }
  }
}

// ========== 主程序 ==========
async function main() {
  const selector = new BundleSelector();
  await selector.start();
}

// 如果直接运行此文件，则执行主程序
if (require.main === module) {
  main().catch(error => {
    console.error('程序异常退出:', error.message);
    process.exit(1);
  });
}

module.exports = { BundleSelector }; 