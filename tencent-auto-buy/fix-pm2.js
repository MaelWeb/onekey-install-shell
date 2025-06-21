#!/usr/bin/env node

/**
 * @fileoverview PM2 问题快速修复脚本
 * @description 修复 PM2 环境下的 readline 错误
 */

const { spawn } = require('child_process');

async function fixPM2Issue() {
  console.log('🔧 开始修复 PM2 问题...');
  
  try {
    // 1. 停止现有服务
    console.log('1️⃣  停止现有 PM2 服务...');
    await executeCommand('pm2 stop tencent-auto-buy');
    console.log('✅ 服务已停止');
    
    // 2. 删除现有服务
    console.log('2️⃣  删除现有 PM2 服务...');
    await executeCommand('pm2 delete tencent-auto-buy');
    console.log('✅ 服务已删除');
    
    // 3. 清理日志
    console.log('3️⃣  清理日志文件...');
    await executeCommand('rm -f ./logs/*.log');
    console.log('✅ 日志已清理');
    
    // 4. 重新启动服务
    console.log('4️⃣  重新启动 PM2 服务...');
    await executeCommand('pm2 start ecosystem.config.js');
    console.log('✅ 服务已重新启动');
    
    // 5. 显示状态
    console.log('5️⃣  显示服务状态...');
    await executeCommand('pm2 status');
    
    console.log('\n🎉 PM2 问题修复完成！');
    console.log('现在可以查看日志：');
    console.log('  pm2 logs tencent-auto-buy');
    
  } catch (error) {
    console.error('❌ 修复失败:', error.message);
    console.log('\n💡 手动修复步骤：');
    console.log('1. pm2 stop tencent-auto-buy');
    console.log('2. pm2 delete tencent-auto-buy');
    console.log('3. pm2 start ecosystem.config.js');
    console.log('4. pm2 logs tencent-auto-buy');
  }
}

function executeCommand(command) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, [], {
      stdio: 'inherit',
      shell: true
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`命令执行失败: ${command}`));
      }
    });

    child.on('error', (error) => {
      reject(new Error(`命令执行错误: ${error.message}`));
    });
  });
}

// 运行修复
if (require.main === module) {
  fixPM2Issue().catch(error => {
    console.error('修复异常退出:', error.message);
    process.exit(1);
  });
}

module.exports = { fixPM2Issue }; 