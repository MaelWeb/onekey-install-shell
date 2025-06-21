#!/usr/bin/env node

/**
 * @fileoverview 腾讯云凭证测试脚本
 * @description 用于测试腾讯云 API 凭证是否有效
 */

const fs = require('fs').promises;

// 加载配置
async function loadConfig() {
  try {
    const configData = await fs.readFile('./config.json', 'utf8');
    return JSON.parse(configData);
  } catch (error) {
    console.error('加载配置文件失败:', error.message);
    process.exit(1);
  }
}

// 测试凭证
async function testCredentials() {
  try {
    console.log('🔍 开始测试腾讯云凭证...');
    
    const config = await loadConfig();
    console.log('📋 配置信息:');
    console.log(`  SecretId: ${config.secretId}`);
    console.log(`  SecretKey: ${config.secretKey.substring(0, 10)}...`);
    console.log(`  Region: ${config.region}`);
    
    // 正确导入腾讯云 SDK
    const tencentcloud = require('tencentcloud-sdk-nodejs');
    const LighthouseClient = tencentcloud.lighthouse.v20200324.Client;
    
    const client = new LighthouseClient({
      credential: { 
        secretId: config.secretId, 
        secretKey: config.secretKey 
      },
      region: config.region,
    });
    
    console.log('✅ 客户端初始化成功');
    
    // 测试 API 调用
    console.log('🔄 正在测试 API 调用...');
    const req = {
      Limit: 1
    };
    
    const resp = await client.DescribeBundles(req);
    console.log('✅ API 调用成功');
    console.log('📊 响应数据:', JSON.stringify(resp, null, 2));
    
    // 测试查询锐驰型套餐
    console.log('🔄 正在查询锐驰型套餐...');
    const razorReq = {
      Filters: [{ Name: 'bundle-type', Values: ['RAZOR_SPEED_BUNDLE'] }],
    };
    
    const razorResp = await client.DescribeBundles(razorReq);
    console.log('✅ 锐驰型套餐查询成功');
    console.log(`📊 找到 ${razorResp.BundleSet ? razorResp.BundleSet.length : 0} 个锐驰型套餐`);
    
    if (razorResp.BundleSet && razorResp.BundleSet.length > 0) {
      console.log('📋 套餐列表:');
      razorResp.BundleSet.forEach((bundle, index) => {
        const price = formatPrice(bundle.Price);
        console.log(`  ${index + 1}. ${bundle.BundleId}: ${bundle.CPU}核${bundle.Memory}GB - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
      });
    }
    
    console.log('🎉 所有测试通过！凭证有效。');
    
  } catch (error) {
    console.error('❌ 测试失败:');
    console.error('  错误信息:', error.message);
    console.error('  错误代码:', error.code);
    console.error('  错误名称:', error.name);
    
    if (error.code === 'AuthFailure') {
      console.error('🔐 认证失败 - 请检查 SecretId 和 SecretKey 是否正确');
    } else if (error.code === 'InvalidParameter') {
      console.error('📝 参数错误 - 请检查配置参数');
    } else if (error.code === 'NetworkError') {
      console.error('🌐 网络错误 - 请检查网络连接');
    }
    
    console.error('📋 完整错误信息:', error);
    process.exit(1);
  }
}

/**
 * 格式化价格信息
 * @param {Object} price - 价格对象
 * @returns {string} 格式化后的价格字符串
 */
function formatPrice(price) {
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

// 运行测试
if (require.main === module) {
  testCredentials();
}

module.exports = { testCredentials }; 