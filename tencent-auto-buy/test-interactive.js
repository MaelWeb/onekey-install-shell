#!/usr/bin/env node

/**
 * @fileoverview 交互功能测试脚本
 * @description 用于测试交互式套餐选择功能，使用模拟数据
 */

const readline = require('readline');

// 模拟套餐数据
const mockBundles = [
  {
    BundleId: 'bundle-razor-1c1g',
    CPU: 1,
    Memory: 1,
    BundleSalesState: 'AVAILABLE',
    InternetMaxBandwidthOut: '30',
    BundleDisplayTitle: '1核1GB'
  },
  {
    BundleId: 'bundle-razor-2c2g',
    CPU: 2,
    Memory: 2,
    BundleSalesState: 'AVAILABLE',
    InternetMaxBandwidthOut: '30',
    BundleDisplayTitle: '2核2GB'
  },
  {
    BundleId: 'bundle-razor-4c4g',
    CPU: 4,
    Memory: 4,
    BundleSalesState: 'SOLD_OUT',
    InternetMaxBandwidthOut: '30',
    BundleDisplayTitle: '4核4GB'
  },
  {
    BundleId: 'bundle-razor-8c8g',
    CPU: 8,
    Memory: 8,
    BundleSalesState: 'AVAILABLE',
    InternetMaxBandwidthOut: '30',
    BundleDisplayTitle: '8核8GB'
  }
];

// 模拟配置
const mockConfig = {
  secretId: 'test-secret-id',
  secretKey: 'test-secret-key',
  region: 'ap-hongkong',
  bundleId: 'bundle-razor-xxxx',
  blueprintId: 'lhbp-xxxx',
  instanceNamePrefix: 'auto-ruichi',
  instanceCount: 1,
  checkInterval: 10000,
  maxRetries: 3,
  exitAfterPurchase: false,
  logFile: './test.log',
  interactiveMode: true
};

// 交互式命令行工具类（从主脚本复制）
class InteractiveCLI {
  constructor(rl) {
    this.rl = rl;
  }

  async selectBundle(bundles) {
    console.log('\n📋 可用的锐驰型套餐列表：');
    console.log('='.repeat(80));
    
    const availableBundles = bundles.filter(b => b.BundleSalesState === 'AVAILABLE');
    const unavailableBundles = bundles.filter(b => b.BundleSalesState !== 'AVAILABLE');
    
    if (availableBundles.length > 0) {
      console.log('\n✅ 有库存的套餐：');
      availableBundles.forEach((bundle, index) => {
        const bandwidth = bundle.InternetMaxBandwidthOut ? `${bundle.InternetMaxBandwidthOut}Mbps` : '未知';
        const title = bundle.BundleDisplayTitle || `${bundle.CPU}核${bundle.Memory}GB`;
        console.log(`  ${index + 1}. ${bundle.BundleId} - ${title} - 带宽: ${bandwidth} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    if (unavailableBundles.length > 0) {
      console.log('\n❌ 无库存的套餐：');
      unavailableBundles.forEach((bundle, index) => {
        const bandwidth = bundle.InternetMaxBandwidthOut ? `${bundle.InternetMaxBandwidthOut}Mbps` : '未知';
        const title = bundle.BundleDisplayTitle || `${bundle.CPU}核${bundle.Memory}GB`;
        console.log(`  ${availableBundles.length + index + 1}. ${bundle.BundleId} - ${title} - 带宽: ${bandwidth} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    console.log('\n' + '='.repeat(80));
    
    const selectedIndex = await this.promptForNumber(
      `请选择套餐 (1-${bundles.length})，或输入 0 退出: `,
      0,
      bundles.length
    );
    
    if (selectedIndex === 0) {
      throw new Error('用户取消选择');
    }
    
    const selectedBundle = bundles[selectedIndex - 1];
    console.log(`\n✅ 已选择套餐: ${selectedBundle.BundleId} - ${selectedBundle.CPU}核${selectedBundle.Memory}GB`);
    
    return selectedBundle.BundleId;
  }

  async confirmSaveSelection(bundleId) {
    const answer = await this.promptForYesNo(
      `是否将套餐 ${bundleId} 保存到配置文件？(y/N): `,
      false
    );
    return answer;
  }

  async confirmStartMonitoring() {
    const answer = await this.promptForYesNo(
      '是否立即开始监控该套餐的库存？(Y/n): ',
      true
    );
    return answer;
  }

  promptForNumber(question, min, max) {
    return new Promise((resolve) => {
      const askQuestion = () => {
        this.rl.question(question, (answer) => {
          const num = parseInt(answer, 10);
          if (isNaN(num) || num < min || num > max) {
            console.log(`❌ 请输入 ${min}-${max} 之间的数字`);
            askQuestion();
          } else {
            resolve(num);
          }
        });
      };
      askQuestion();
    });
  }

  promptForYesNo(question, defaultAnswer) {
    return new Promise((resolve) => {
      this.rl.question(question, (answer) => {
        const lowerAnswer = answer.toLowerCase().trim();
        if (lowerAnswer === '' || lowerAnswer === 'y' || lowerAnswer === 'yes') {
          resolve(true);
        } else if (lowerAnswer === 'n' || lowerAnswer === 'no') {
          resolve(false);
        } else {
          console.log('❌ 请输入 y/yes 或 n/no');
          this.promptForYesNo(question, defaultAnswer).then(resolve);
        }
      });
    });
  }

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

// 测试主函数
async function testInteractive() {
  console.log('🧪 开始测试交互式套餐选择功能...');
  
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  const cli = new InteractiveCLI(rl);
  
  try {
    // 显示当前配置
    cli.showCurrentConfig(mockConfig);
    
    // 用户选择套餐
    const selectedBundleId = await cli.selectBundle(mockBundles);
    
    // 询问是否保存选择
    const shouldSave = await cli.confirmSaveSelection(selectedBundleId);
    if (shouldSave) {
      console.log(`✅ 模拟保存套餐选择到配置文件: ${selectedBundleId}`);
    }
    
    // 询问是否立即开始监控
    const shouldStartMonitoring = await cli.confirmStartMonitoring();
    if (shouldStartMonitoring) {
      console.log('✅ 模拟开始监控套餐库存...');
    } else {
      console.log('ℹ️ 用户选择不立即开始监控');
    }
    
    console.log('\n🎉 交互功能测试完成！');
    
  } catch (error) {
    if (error.message === '用户取消选择') {
      console.log('ℹ️ 用户取消选择，测试结束');
    } else {
      console.error('❌ 测试过程中出现错误:', error.message);
    }
  } finally {
    rl.close();
  }
}

// 运行测试
if (require.main === module) {
  testInteractive().catch(error => {
    console.error('测试失败:', error.message);
    process.exit(1);
  });
}

module.exports = { testInteractive, InteractiveCLI }; 