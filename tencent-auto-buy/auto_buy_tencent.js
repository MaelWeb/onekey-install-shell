#!/usr/bin/env node

/**
 * @fileoverview 腾讯云轻量应用服务器自动购买脚本
 * @author edenliang edenliang@tencent.com
 * @version 2.0.0
 * @description 自动监控并购买腾讯云轻量应用服务器锐驰型套餐
 */

const { v4: uuidv4 } = require('uuid');
const fs = require('fs').promises;
const path = require('path');
const readline = require('readline');

// ========== 类型定义 ==========
/**
 * @typedef {Object} Config
 * @property {string} secretId - 腾讯云 Secret ID
 * @property {string} secretKey - 腾讯云 Secret Key
 * @property {string} region - 地域
 * @property {string} bundleId - 目标套餐 ID
 * @property {string} blueprintId - 镜像 ID
 * @property {string} instanceNamePrefix - 实例名称前缀
 * @property {number} instanceCount - 购买数量
 * @property {number} checkInterval - 轮询间隔（毫秒）
 * @property {number} maxRetries - 最大重试次数
 * @property {boolean} exitAfterPurchase - 购买后是否退出
 * @property {string} logFile - 日志文件路径
 * @property {boolean} interactiveMode - 是否启用交互模式
 */

/**
 * @typedef {Object} BundleInfo
 * @property {string} BundleId - 套餐 ID
 * @property {number} CPU - CPU 核心数
 * @property {number} Memory - 内存大小（GB）
 * @property {string} BundleSalesState - 销售状态
 * @property {string} Price - 价格信息
 * @property {string} InternetMaxBandwidthOut - 带宽信息
 * @property {string} BundleDisplayTitle - 套餐显示标题
 */

// ========== 默认配置 ==========
const DEFAULT_CONFIG = {
  secretId: process.env.TENCENT_SECRET_ID || 'YOUR_SECRET_ID',
  secretKey: process.env.TENCENT_SECRET_KEY || 'YOUR_SECRET_KEY',
  region: 'ap-hongkong',
  bundleId: 'bundle-razor-xxxx',
  blueprintId: 'lhbp-xxxx',
  instanceNamePrefix: 'auto-ruichi',
  instanceCount: 1,
  checkInterval: 10000,
  maxRetries: 3,
  exitAfterPurchase: false,
  logFile: './auto-buy.log',
  interactiveMode: process.env.INTERACTIVE_MODE !== 'false'  // 支持环境变量控制
};

// ========== 交互式命令行工具 ==========
class InteractiveCLI {
  /**
   * @param {readline.Interface} rl - readline 接口
   */
  constructor(rl) {
    this.rl = rl;
  }

  /**
   * 显示套餐列表供用户选择
   * @param {BundleInfo[]} bundles - 套餐列表
   * @returns {Promise<string>} 用户选择的套餐 ID
   */
  async selectBundle(bundles) {
    console.log('\n📋 可用的锐驰型套餐列表：');
    console.log('='.repeat(100));
    
    const availableBundles = bundles.filter(b => b.BundleSalesState === 'AVAILABLE');
    const unavailableBundles = bundles.filter(b => b.BundleSalesState !== 'AVAILABLE');
    
    // 创建完整的套餐列表，按显示顺序排列
    const displayBundles = [...availableBundles, ...unavailableBundles];
    
    // 显示可用套餐
    if (availableBundles.length > 0) {
      console.log('\n✅ 有库存的套餐：');
      availableBundles.forEach((bundle, index) => {
        const bandwidth = bundle.InternetMaxBandwidthOut ? `${bundle.InternetMaxBandwidthOut}Mbps` : '未知';
        const title = bundle.BundleDisplayTitle || `${bundle.CPU}核${bundle.Memory}GB`;
        const price = this.formatPrice(bundle.Price);
        console.log(`  ${index + 1}. ${bundle.BundleId} - ${title} - 带宽: ${bandwidth} - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    // 显示无库存套餐
    if (unavailableBundles.length > 0) {
      console.log('\n❌ 无库存的套餐：');
      unavailableBundles.forEach((bundle, index) => {
        const bandwidth = bundle.InternetMaxBandwidthOut ? `${bundle.InternetMaxBandwidthOut}Mbps` : '未知';
        const title = bundle.BundleDisplayTitle || `${bundle.CPU}核${bundle.Memory}GB`;
        const price = this.formatPrice(bundle.Price);
        console.log(`  ${availableBundles.length + index + 1}. ${bundle.BundleId} - ${title} - 带宽: ${bandwidth} - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    console.log('\n' + '='.repeat(100));
    
    // 用户选择
    const selectedIndex = await this.promptForNumber(
      `请选择套餐 (1-${bundles.length})，或输入 0 退出: `,
      0,
      bundles.length
    );
    
    if (selectedIndex === 0) {
      throw new Error('用户取消选择');
    }
    
    // 根据用户选择找到对应的套餐
    let selectedBundle;
    if (selectedIndex <= availableBundles.length) {
      // 选择的是有库存的套餐
      selectedBundle = availableBundles[selectedIndex - 1];
    } else {
      // 选择的是无库存的套餐
      const unavailableIndex = selectedIndex - availableBundles.length - 1;
      selectedBundle = unavailableBundles[unavailableIndex];
    }
    
    const price = this.formatPrice(selectedBundle.Price);
    console.log(`\n✅ 已选择套餐: ${selectedBundle.BundleId} - ${selectedBundle.CPU}核${selectedBundle.Memory}GB - 价格: ${price}`);
    
    return selectedBundle.BundleId;
  }

  /**
   * 格式化价格信息
   * @param {Object} price - 价格对象
   * @returns {string} 格式化后的价格字符串
   */
  formatPrice(price) {
    if (!price || !price.InstancePrice) {
      return '价格未知';
    }
    
    const instancePrice = price.InstancePrice;
    const currency = instancePrice.Currency || 'CNY';
    const originalPrice = instancePrice.OriginalPrice;
    const discountPrice = instancePrice.DiscountPrice;
    const discount = instancePrice.Discount;
    
    if (discount === 100) {
      return `${currency} ${originalPrice}/月`;
    } else {
      return `${currency} ${originalPrice}/月 (优惠价: ${discountPrice}/月)`;
    }
  }

  /**
   * 询问是否保存选择到配置文件
   * @param {string} bundleId - 选择的套餐 ID
   * @returns {Promise<boolean>}
   */
  async confirmSaveSelection(bundleId) {
    const answer = await this.promptForYesNo(
      `是否将套餐 ${bundleId} 保存到配置文件？(y/N): `,
      false
    );
    return answer;
  }

  /**
   * 询问是否立即开始监控
   * @returns {Promise<boolean>}
   */
  async confirmStartMonitoring() {
    const answer = await this.promptForYesNo(
      '是否立即开始监控该套餐的库存？(Y/n): ',
      true
    );
    return answer;
  }

  /**
   * 提示用户输入数字
   * @param {string} question - 问题
   * @param {number} min - 最小值
   * @param {number} max - 最大值
   * @returns {Promise<number>}
   */
  promptForNumber(question, min, max) {
    return new Promise((resolve, reject) => {
      // 检查 readline 接口是否已关闭
      if (!this.rl || this.rl.closed) {
        reject(new Error('readline 接口已关闭，无法进行交互式操作'));
        return;
      }

      const askQuestion = () => {
        try {
          this.rl.question(question, (answer) => {
            const num = parseInt(answer, 10);
            if (isNaN(num) || num < min || num > max) {
              console.log(`❌ 请输入 ${min}-${max} 之间的数字`);
              askQuestion();
            } else {
              resolve(num);
            }
          });
        } catch (error) {
          reject(new Error(`readline 操作失败: ${error.message}`));
        }
      };
      askQuestion();
    });
  }

  /**
   * 提示用户输入是/否
   * @param {string} question - 问题
   * @param {boolean} defaultAnswer - 默认答案
   * @returns {Promise<boolean>}
   */
  promptForYesNo(question, defaultAnswer) {
    return new Promise((resolve, reject) => {
      // 检查 readline 接口是否已关闭
      if (!this.rl || this.rl.closed) {
        reject(new Error('readline 接口已关闭，无法进行交互式操作'));
        return;
      }

      try {
        this.rl.question(question, (answer) => {
          const lowerAnswer = answer.toLowerCase().trim();
          if (lowerAnswer === '' || lowerAnswer === 'y' || lowerAnswer === 'yes') {
            resolve(true);
          } else if (lowerAnswer === 'n' || lowerAnswer === 'no') {
            resolve(false);
          } else {
            console.log('❌ 请输入 y/yes 或 n/no');
            this.promptForYesNo(question, defaultAnswer).then(resolve).catch(reject);
          }
        });
      } catch (error) {
        reject(new Error(`readline 操作失败: ${error.message}`));
      }
    });
  }

  /**
   * 显示当前配置信息
   * @param {Config} config - 配置对象
   */
  showCurrentConfig(config) {
    console.log('\n📋 当前配置信息：');
    console.log('='.repeat(50));
    console.log(`地域: ${config.region}`);
    console.log(`目标套餐: ${config.bundleId}`);
    console.log(`镜像ID: ${config.blueprintId}`);
    console.log(`实例名称前缀: ${config.instanceNamePrefix}`);
    console.log(`购买数量: ${config.instanceCount}`);
    console.log(`轮询间隔: ${config.checkInterval}ms`);
    console.log(`最大重试次数: ${config.maxRetries}`);
    console.log(`购买后退出: ${config.exitAfterPurchase ? '是' : '否'}`);
    console.log('='.repeat(50));
  }
}

// ========== 日志系统 ==========
class Logger {
  /**
   * @param {string} logFile - 日志文件路径
   */
  constructor(logFile) {
    this.logFile = logFile;
  }

  /**
   * @param {string} level - 日志级别
   * @param {string} message - 日志消息
   * @param {any} [data] - 附加数据
   */
  async log(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level,
      message,
      data
    };

    const consoleMessage = `[${timestamp}] ${level.toUpperCase()}: ${message}`;
    
    // 控制台输出
    switch (level) {
      case 'info':
        console.log('ℹ️', consoleMessage);
        break;
      case 'success':
        console.log('✅', consoleMessage);
        break;
      case 'warning':
        console.warn('⚠️', consoleMessage);
        break;
      case 'error':
        console.error('❌', consoleMessage);
        break;
      default:
        console.log(consoleMessage);
    }

    // 文件日志
    try {
      await fs.appendFile(this.logFile, JSON.stringify(logEntry) + '\n');
    } catch (error) {
      console.error('Failed to write to log file:', error.message);
    }
  }

  info(message, data) { return this.log('info', message, data); }
  success(message, data) { return this.log('success', message, data); }
  warning(message, data) { return this.log('warning', message, data); }
  error(message, data) { return this.log('error', message, data); }
}

// ========== 配置管理 ==========
class ConfigManager {
  /**
   * @param {string} configPath - 配置文件路径
   */
  constructor(configPath = './config.json') {
    this.configPath = configPath;
  }

  /**
   * 加载配置文件
   * @returns {Promise<Config>}
   */
  async loadConfig() {
    try {
      const configData = await fs.readFile(this.configPath, 'utf8');
      const userConfig = JSON.parse(configData);
      return { ...DEFAULT_CONFIG, ...userConfig };
    } catch (error) {
      if (error.code === 'ENOENT') {
        // 配置文件不存在，创建默认配置
        await this.createDefaultConfig();
        return DEFAULT_CONFIG;
      }
      throw new Error(`Failed to load config: ${error.message}`);
    }
  }

  /**
   * 保存配置到文件
   * @param {Config} config - 配置对象
   */
  async saveConfig(config) {
    try {
      await fs.writeFile(this.configPath, JSON.stringify(config, null, 2));
    } catch (error) {
      throw new Error(`Failed to save config: ${error.message}`);
    }
  }

  /**
   * 更新配置中的套餐 ID
   * @param {string} bundleId - 新的套餐 ID
   */
  async updateBundleId(bundleId) {
    const config = await this.loadConfig();
    config.bundleId = bundleId;
    await this.saveConfig(config);
  }

  /**
   * 创建默认配置文件
   */
  async createDefaultConfig() {
    try {
      await fs.writeFile(this.configPath, JSON.stringify(DEFAULT_CONFIG, null, 2));
      console.log(`📝 已创建默认配置文件: ${this.configPath}`);
      console.log('请编辑配置文件并填入正确的腾讯云凭证信息');
    } catch (error) {
      throw new Error(`Failed to create config file: ${error.message}`);
    }
  }
}

// ========== 腾讯云客户端管理 ==========
class TencentCloudClient {
  /**
   * @param {Config} config - 配置对象
   */
  constructor(config) {
    this.config = config;
    
    // 正确导入腾讯云 SDK
    const tencentcloud = require('tencentcloud-sdk-nodejs');
    this.LighthouseClient = tencentcloud.lighthouse.v20200324.Client;
    
    this.client = new this.LighthouseClient({
      credential: { 
        secretId: config.secretId, 
        secretKey: config.secretKey 
      },
      region: config.region,
    });
  }

  /**
   * 验证凭证有效性
   * @returns {Promise<boolean>}
   */
  async validateCredentials() {
    try {
      const req = {
        Limit: 1
      };
      await this.client.DescribeBundles(req);
      return true;
    } catch (error) {
      if (error.code === 'AuthFailure') {
        throw new Error('腾讯云凭证无效，请检查 SecretId 和 SecretKey');
      }
      throw error;
    }
  }

  /**
   * 查询锐驰型套餐列表
   * @returns {Promise<BundleInfo[]>}
   */
  async listRazorBundles() {
    const req = {
      Filters: [{ Name: 'bundle-type', Values: ['RAZOR_SPEED_BUNDLE'] }],
    };

    try {
      const resp = await this.client.DescribeBundles(req);
      return resp.BundleSet || [];
    } catch (error) {
      throw new Error(`查询套餐列表失败: ${error.message}`);
    }
  }

  /**
   * 检查指定套餐是否有库存
   * @param {string} bundleId - 套餐 ID
   * @returns {Promise<boolean>}
   */
  async isInStock(bundleId) {
    // 使用与 listRazorBundles 相同的过滤条件，确保数据一致性
    const req = {
      Filters: [{ Name: 'bundle-type', Values: ['RAZOR_SPEED_BUNDLE'] }],
    };

    try {
      const resp = await this.client.DescribeBundles(req);
      if (!resp.BundleSet || resp.BundleSet.length === 0) {
        console.log(`⚠️  未找到任何锐驰型套餐`);
        return false;
      }

      // 在锐驰型套餐中查找指定的套餐ID
      const targetBundle = resp.BundleSet.find(bundle => bundle.BundleId === bundleId);
      
      if (!targetBundle) {
        console.log(`⚠️  在锐驰型套餐列表中未找到套餐: ${bundleId}`);
        console.log(`📋 可用的锐驰型套餐: ${resp.BundleSet.map(b => b.BundleId).join(', ')}`);
        return false;
      }

      const isAvailable = targetBundle.BundleSalesState === 'AVAILABLE';
      
      // 添加详细的调试信息
      console.log(`🔍 套餐 ${bundleId} 库存检查详情:`);
      console.log(`   - 套餐ID: ${targetBundle.BundleId}`);
      console.log(`   - 显示标题: ${targetBundle.BundleDisplayTitle || 'N/A'}`);
      console.log(`   - CPU: ${targetBundle.CPU}核`);
      console.log(`   - 内存: ${targetBundle.Memory}GB`);
      console.log(`   - 销售状态: ${targetBundle.BundleSalesState}`);
      console.log(`   - 带宽: ${targetBundle.InternetMaxBandwidthOut || 'N/A'}Mbps`);
      
      return isAvailable;
    } catch (error) {
      throw new Error(`检查库存状态失败: ${error.message}`);
    }
  }

  /**
   * 购买实例
   * @param {string} bundleId - 套餐 ID
   * @returns {Promise<{success: boolean, instanceIds?: string[], error?: string}>}
   */
  async buyInstance(bundleId) {
    const instanceName = `${this.config.instanceNamePrefix}-${uuidv4().slice(0, 6)}`;
    
    const req = {
      BundleId: bundleId,
      BlueprintId: this.config.blueprintId,
      InstanceName: instanceName,
      InstanceCount: this.config.instanceCount,
      ClientToken: uuidv4(),
      InstanceChargePrepaid: { 
        Period: 1, 
        RenewFlag: 'NOTIFY_AND_MANUAL_RENEW' 
      },
    };

    try {
      const resp = await this.client.CreateInstances(req);
      return {
        success: true,
        instanceIds: resp.InstanceIdSet || []
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * 调试方法：对比不同查询方式的结果
   * @param {string} bundleId - 套餐 ID
   * @returns {Promise<void>}
   */
  async debugBundleStatus(bundleId) {
    console.log('\n🔍 开始调试套餐状态查询...');
    console.log('='.repeat(60));
    
    try {
      // 方法1：使用 bundle-type 过滤（与 listRazorBundles 相同）
      console.log('📋 方法1: 使用 bundle-type 过滤查询锐驰型套餐列表');
      const razorReq = {
        Filters: [{ Name: 'bundle-type', Values: ['RAZOR_SPEED_BUNDLE'] }],
      };
      const razorResp = await this.client.DescribeBundles(razorReq);
      const razorBundle = razorResp.BundleSet?.find(b => b.BundleId === bundleId);
      
      if (razorBundle) {
        console.log(`✅ 在锐驰型套餐列表中找到: ${bundleId}`);
        console.log(`   状态: ${razorBundle.BundleSalesState}`);
        console.log(`   标题: ${razorBundle.BundleDisplayTitle || 'N/A'}`);
      } else {
        console.log(`❌ 在锐驰型套餐列表中未找到: ${bundleId}`);
        console.log(`   可用的锐驰型套餐: ${razorResp.BundleSet?.map(b => b.BundleId).join(', ') || '无'}`);
      }
      
      console.log('\n' + '-'.repeat(40));
      
      // 方法2：使用 bundle-id 过滤（原来的方法）
      console.log('📋 方法2: 使用 bundle-id 过滤查询指定套餐');
      const bundleReq = {
        Filters: [{ Name: 'bundle-id', Values: [bundleId] }],
      };
      const bundleResp = await this.client.DescribeBundles(bundleReq);
      
      if (bundleResp.BundleSet && bundleResp.BundleSet.length > 0) {
        const bundle = bundleResp.BundleSet[0];
        console.log(`✅ 直接查询套餐ID找到: ${bundleId}`);
        console.log(`   状态: ${bundle.BundleSalesState}`);
        console.log(`   标题: ${bundle.BundleDisplayTitle || 'N/A'}`);
        console.log(`   类型: ${bundle.BundleType || 'N/A'}`);
      } else {
        console.log(`❌ 直接查询套餐ID未找到: ${bundleId}`);
      }
      
      console.log('\n' + '='.repeat(60));
      
      // 对比结果
      if (razorBundle && bundleResp.BundleSet && bundleResp.BundleSet.length > 0) {
        const bundle = bundleResp.BundleSet[0];
        if (razorBundle.BundleSalesState !== bundle.BundleSalesState) {
          console.log('⚠️  警告: 两种查询方式返回的状态不一致!');
          console.log(`   锐驰型列表查询: ${razorBundle.BundleSalesState}`);
          console.log(`   直接套餐查询: ${bundle.BundleSalesState}`);
        } else {
          console.log('✅ 两种查询方式返回的状态一致');
        }
      }
      
    } catch (error) {
      console.error('❌ 调试过程中发生错误:', error.message);
    }
  }
}

// ========== 自动购买管理器 ==========
class AutoBuyManager {
  /**
   * @param {Config} config - 配置对象
   * @param {TencentCloudClient} client - 腾讯云客户端
   * @param {Logger} logger - 日志记录器
   * @param {InteractiveCLI} cli - 交互式命令行工具
   */
  constructor(config, client, logger, cli = null) {
    this.config = config;
    this.client = client;
    this.logger = logger;
    this.cli = cli;
    this.isRunning = false;
    this.retryCount = 0;
    this.purchaseCount = 0;
  }

  /**
   * 启动自动购买流程
   */
  async start() {
    this.isRunning = true;
    
    try {
      // 验证凭证
      await this.logger.info('正在验证腾讯云凭证...');
      await this.client.validateCredentials();
      await this.logger.success('凭证验证成功');

      // 检查配置文件中的套餐是否有效
      if (this.config.bundleId && this.config.bundleId !== 'bundle-razor-xxxx') {
        // 配置文件中有指定套餐，直接开始监控
        await this.logger.info(`使用配置文件中的套餐: ${this.config.bundleId}`);
        await this.logger.info(`开始轮询套餐 ${this.config.bundleId} 的库存情况...`);
        await this.startPolling();
      } else {
        // 配置文件中没有指定套餐，进行交互式选择
        if (this.config.interactiveMode && this.cli) {
          await this.logger.info('正在查询锐驰型套餐列表...');
          const bundles = await this.client.listRazorBundles();
          await this.logger.info(`找到 ${bundles.length} 个锐驰型套餐`);
          await this.handleInteractiveSelection(bundles);
        } else {
          await this.logger.error('配置文件中没有指定套餐，且无法进行交互式选择');
          process.exit(1);
        }
      }

    } catch (error) {
      console.error('AutoBuyManager 详细错误信息:', error);
      console.error('AutoBuyManager 错误堆栈:', error.stack);
      await this.logger.error('启动失败', {
        message: error.message,
        stack: error.stack,
        code: error.code,
        name: error.name
      });
      process.exit(1);
    }
  }

  /**
   * 处理交互式套餐选择
   * @param {BundleInfo[]} bundles - 套餐列表
   */
  async handleInteractiveSelection(bundles) {
    try {
      // 检查 CLI 是否可用
      if (!this.cli) {
        throw new Error('交互式 CLI 不可用');
      }

      // 显示当前配置
      this.cli.showCurrentConfig(this.config);
      
      // 用户选择套餐
      const selectedBundleId = await this.cli.selectBundle(bundles);
      
      // 询问是否保存选择
      const shouldSave = await this.cli.confirmSaveSelection(selectedBundleId);
      if (shouldSave) {
        const configManager = new ConfigManager();
        await configManager.updateBundleId(selectedBundleId);
        this.config.bundleId = selectedBundleId;
        await this.logger.success(`套餐选择已保存到配置文件: ${selectedBundleId}`);
      }
      
      // 询问是否立即开始监控
      const shouldStartMonitoring = await this.cli.confirmStartMonitoring();
      if (!shouldStartMonitoring) {
        await this.logger.info('用户选择不立即开始监控，程序退出');
        process.exit(0);
      }
      
    } catch (error) {
      if (error.message === '用户取消选择') {
        await this.logger.info('用户取消选择，程序退出');
        process.exit(0);
      }
      
      // 处理 readline 相关错误
      if (error.message.includes('readline') || error.message.includes('ERR_USE_AFTER_CLOSE')) {
        await this.logger.warning('检测到 readline 错误，切换到非交互模式');
        await this.logger.info(`使用配置文件中的套餐: ${this.config.bundleId}`);
        return; // 继续执行，不退出程序
      }
      
      throw error;
    }
  }

  /**
   * 显示套餐列表
   * @param {BundleInfo[]} bundles - 套餐列表
   */
  displayBundles(bundles) {
    console.log('\n📋 锐驰型套餐列表：');
    console.log('='.repeat(100));
    
    const availableBundles = bundles.filter(b => b.BundleSalesState === 'AVAILABLE');
    const unavailableBundles = bundles.filter(b => b.BundleSalesState !== 'AVAILABLE');
    
    if (availableBundles.length > 0) {
      console.log('\n✅ 有库存的套餐：');
      availableBundles.forEach(bundle => {
        const bandwidth = bundle.InternetMaxBandwidthOut ? `${bundle.InternetMaxBandwidthOut}Mbps` : '未知';
        const title = bundle.BundleDisplayTitle || `${bundle.CPU}核${bundle.Memory}GB`;
        const price = this.formatPrice(bundle.Price);
        console.log(` • ${bundle.BundleId}: ${title} - 带宽: ${bandwidth} - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    if (unavailableBundles.length > 0) {
      console.log('\n❌ 无库存的套餐：');
      unavailableBundles.forEach(bundle => {
        const bandwidth = bundle.InternetMaxBandwidthOut ? `${bundle.InternetMaxBandwidthOut}Mbps` : '未知';
        const title = bundle.BundleDisplayTitle || `${bundle.CPU}核${bundle.Memory}GB`;
        const price = this.formatPrice(bundle.Price);
        console.log(` • ${bundle.BundleId}: ${title} - 带宽: ${bandwidth} - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    console.log('\n' + '='.repeat(100));
  }

  /**
   * 格式化价格信息
   * @param {Object} price - 价格对象
   * @returns {string} 格式化后的价格字符串
   */
  formatPrice(price) {
    if (!price || !price.InstancePrice) {
      return '价格未知';
    }
    
    const instancePrice = price.InstancePrice;
    const currency = instancePrice.Currency || 'CNY';
    const originalPrice = instancePrice.OriginalPrice;
    const discountPrice = instancePrice.DiscountPrice;
    const discount = instancePrice.Discount;
    
    if (discount === 100) {
      return `${currency} ${originalPrice}/月`;
    } else {
      return `${currency} ${originalPrice}/月 (优惠价: ${discountPrice}/月)`;
    }
  }

  /**
   * 开始轮询库存
   */
  async startPolling() {
    while (this.isRunning) {
      try {
        const isAvailable = await this.client.isInStock(this.config.bundleId);
        
        await this.logger.info(
          `库存状态: ${isAvailable ? 'AVAILABLE' : 'UNAVAILABLE'}`,
          { bundleId: this.config.bundleId, timestamp: new Date().toISOString() }
        );

        if (isAvailable) {
          await this.logger.info('⚡ 检测到可用库存，尝试下单...');
          await this.attemptPurchase();
        }

        // 重置重试计数
        this.retryCount = 0;

      } catch (error) {
        this.retryCount++;
        await this.logger.warning(`轮询异常 (第${this.retryCount}次)`, error.message);

        if (this.retryCount >= this.config.maxRetries) {
          await this.logger.error('达到最大重试次数，程序退出');
          process.exit(1);
        }
      }

      // 等待下次轮询
      await this.sleep(this.config.checkInterval);
    }
  }

  /**
   * 尝试购买实例
   */
  async attemptPurchase() {
    const result = await this.client.buyInstance(this.config.bundleId);
    
    if (result.success) {
      this.purchaseCount++;
      await this.logger.success(
        `下单成功！实例ID: ${result.instanceIds.join(', ')}`,
        { 
          instanceIds: result.instanceIds,
          purchaseCount: this.purchaseCount 
        }
      );

      if (this.config.exitAfterPurchase) {
        await this.logger.info('配置为购买后退出，程序即将结束');
        this.stop();
      }
    } else {
      await this.logger.error('下单失败', result.error);
    }
  }

  /**
   * 停止轮询
   */
  stop() {
    this.isRunning = false;
  }

  /**
   * 睡眠函数
   * @param {number} ms - 毫秒数
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ========== 主程序 ==========
async function main() {
  const logger = new Logger(DEFAULT_CONFIG.logFile);
  
  try {
    // 加载配置
    await logger.info('正在加载配置文件...');
    const configManager = new ConfigManager();
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
    
    // 根据交互模式决定是否初始化 CLI
    let cli = null;
    let rl = null;
    
    if (config.interactiveMode) {
      // 交互模式：初始化交互式命令行工具
      await logger.info('正在初始化交互式命令行工具...');
      rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });
      cli = new InteractiveCLI(rl);
      await logger.success('交互式命令行工具初始化成功');
    } else {
      // 非交互模式：跳过 CLI 初始化
      await logger.info('非交互模式，跳过交互式命令行工具初始化');
    }
    
    // 初始化管理器
    await logger.info('正在初始化自动购买管理器...');
    const manager = new AutoBuyManager(config, client, logger, cli);
    await logger.success('自动购买管理器初始化成功');

    // 设置优雅退出
    const gracefulShutdown = async (signal) => {
      await logger.info(`收到信号 ${signal}，正在优雅退出...`);
      manager.stop();
      if (rl) {
        rl.close();
      }
      await logger.info('程序已退出');
      process.exit(0);
    };

    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

    // 启动自动购买
    await logger.info('开始启动自动购买流程...');
    await manager.start();

  } catch (error) {
    console.error('详细错误信息:', error);
    console.error('错误堆栈:', error.stack);
    await logger.error('程序启动失败', {
      message: error.message,
      stack: error.stack,
      code: error.code,
      name: error.name
    });
    process.exit(1);
  }
}

// 如果直接运行此文件，则执行主程序
if (require.main === module) {
  main().catch(error => {
    console.error('程序异常退出:', error.message);
    process.exit(1);
  });
}

module.exports = {
  AutoBuyManager,
  TencentCloudClient,
  ConfigManager,
  Logger,
  InteractiveCLI
};
