#!/usr/bin/env node

/**
 * @fileoverview 腾讯云自动购买管理工具
 * @author edenliang edenliang@tencent.com
 * @version 1.0.0
 * @description 提供套餐选择、启动监控、查看状态等功能
 */

const { spawn } = require('child_process');
const readline = require('readline');

// ========== 管理工具 ==========
class AutoBuyManager {
  constructor() {
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  }

  /**
   * 显示主菜单
   */
  showMenu() {
    console.log('\n🚀 腾讯云自动购买管理工具');
    console.log('='.repeat(50));
    console.log('1. 选择套餐 (交互式)');
    console.log('2. 启动自动购买 (PM2)');
    console.log('3. 停止自动购买 (PM2)');
    console.log('4. 重启自动购买 (PM2)');
    console.log('5. 查看运行状态');
    console.log('6. 查看日志');
    console.log('7. 查看套餐列表');
    console.log('0. 退出');
    console.log('='.repeat(50));
  }

  /**
   * 执行 PM2 命令
   * @param {string} command - PM2 命令
   * @returns {Promise<void>}
   */
  async executePM2Command(command) {
    return new Promise((resolve, reject) => {
      const pm2 = spawn('pm2', command.split(' '), {
        stdio: 'inherit',
        shell: true
      });

      pm2.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`PM2 命令执行失败，退出码: ${code}`));
        }
      });

      pm2.on('error', (error) => {
        reject(new Error(`PM2 命令执行错误: ${error.message}`));
      });
    });
  }

  /**
   * 执行 Node.js 脚本
   * @param {string} script - 脚本路径
   * @returns {Promise<void>}
   */
  async executeNodeScript(script) {
    return new Promise((resolve, reject) => {
      const node = spawn('node', [script], {
        stdio: 'inherit',
        shell: true
      });

      node.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`脚本执行失败，退出码: ${code}`));
        }
      });

      node.on('error', (error) => {
        reject(new Error(`脚本执行错误: ${error.message}`));
      });
    });
  }

  /**
   * 选择套餐
   */
  async selectBundle() {
    console.log('\n📋 正在启动套餐选择工具...');
    try {
      await this.executeNodeScript('./select-bundle.js');
      console.log('\n✅ 套餐选择完成');
    } catch (error) {
      console.error('\n❌ 套餐选择失败:', error.message);
    }
  }

  /**
   * 启动自动购买
   */
  async startAutoBuy() {
    console.log('\n🚀 正在启动自动购买服务...');
    try {
      await this.executePM2Command('start ecosystem.config.js');
      console.log('\n✅ 自动购买服务已启动');
    } catch (error) {
      console.error('\n❌ 启动失败:', error.message);
    }
  }

  /**
   * 停止自动购买
   */
  async stopAutoBuy() {
    console.log('\n⏹️  正在停止自动购买服务...');
    try {
      await this.executePM2Command('stop tencent-auto-buy');
      console.log('\n✅ 自动购买服务已停止');
    } catch (error) {
      console.error('\n❌ 停止失败:', error.message);
    }
  }

  /**
   * 重启自动购买
   */
  async restartAutoBuy() {
    console.log('\n🔄 正在重启自动购买服务...');
    try {
      await this.executePM2Command('restart tencent-auto-buy');
      console.log('\n✅ 自动购买服务已重启');
    } catch (error) {
      console.error('\n❌ 重启失败:', error.message);
    }
  }

  /**
   * 查看运行状态
   */
  async showStatus() {
    console.log('\n📊 正在查看运行状态...');
    try {
      await this.executePM2Command('status');
    } catch (error) {
      console.error('\n❌ 查看状态失败:', error.message);
    }
  }

  /**
   * 查看日志
   */
  async showLogs() {
    console.log('\n📝 正在查看日志...');
    try {
      await this.executePM2Command('logs tencent-auto-buy --lines 50');
    } catch (error) {
      console.error('\n❌ 查看日志失败:', error.message);
    }
  }

  /**
   * 查看套餐列表
   */
  async showBundles() {
    console.log('\n📋 正在查询套餐列表...');
    try {
      // 直接运行主脚本查看套餐列表
      const node = spawn('node', ['./auto_buy_tencent.js'], {
        stdio: 'inherit',
        shell: true
      });

      return new Promise((resolve, reject) => {
        node.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`查看套餐列表失败，退出码: ${code}`));
          }
        });

        node.on('error', (error) => {
          reject(new Error(`查看套餐列表错误: ${error.message}`));
        });
      });
    } catch (error) {
      console.error('\n❌ 查看套餐列表失败:', error.message);
    }
  }

  /**
   * 获取用户选择
   * @returns {Promise<number>}
   */
  async getUserChoice() {
    return new Promise((resolve) => {
      this.rl.question('\n请选择操作 (0-7): ', (answer) => {
        const choice = parseInt(answer, 10);
        if (isNaN(choice) || choice < 0 || choice > 7) {
          console.log('❌ 请输入 0-7 之间的数字');
          this.getUserChoice().then(resolve);
        } else {
          resolve(choice);
        }
      });
    });
  }

  /**
   * 运行主循环
   */
  async run() {
    while (true) {
      this.showMenu();
      
      try {
        const choice = await this.getUserChoice();
        
        switch (choice) {
          case 0:
            console.log('\n👋 再见！');
            this.rl.close();
            process.exit(0);
            break;
          case 1:
            await this.selectBundle();
            break;
          case 2:
            await this.startAutoBuy();
            break;
          case 3:
            await this.stopAutoBuy();
            break;
          case 4:
            await this.restartAutoBuy();
            break;
          case 5:
            await this.showStatus();
            break;
          case 6:
            await this.showLogs();
            break;
          case 7:
            await this.showBundles();
            break;
          default:
            console.log('❌ 无效选择');
        }
        
        // 等待用户按回车继续
        await new Promise((resolve) => {
          this.rl.question('\n按回车键继续...', resolve);
        });
        
      } catch (error) {
        console.error('\n❌ 操作失败:', error.message);
        await new Promise((resolve) => {
          this.rl.question('\n按回车键继续...', resolve);
        });
      }
    }
  }
}

// ========== 主程序 ==========
async function main() {
  const manager = new AutoBuyManager();
  
  // 设置优雅退出
  const gracefulShutdown = async (signal) => {
    console.log(`\n收到信号 ${signal}，正在退出...`);
    manager.rl.close();
    process.exit(0);
  };

  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

  await manager.run();
}

// 如果直接运行此文件，则执行主程序
if (require.main === module) {
  main().catch(error => {
    console.error('程序异常退出:', error.message);
    process.exit(1);
  });
}

module.exports = { AutoBuyManager }; 