#!/usr/bin/env node

/**
 * @fileoverview 套餐选择逻辑测试脚本
 */

// 模拟套餐数据
const mockBundles = [
  // 有库存的套餐
  { BundleId: 'bundle_1', CPU: 2, Memory: 2, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 75 } } },
  { BundleId: 'bundle_2', CPU: 2, Memory: 8, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 120 } } },
  { BundleId: 'bundle_3', CPU: 2, Memory: 4, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 130 } } },
  { BundleId: 'bundle_4', CPU: 2, Memory: 8, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 165 } } },
  { BundleId: 'bundle_5', CPU: 4, Memory: 8, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 280 } } },
  { BundleId: 'bundle_6', CPU: 4, Memory: 8, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 380 } } },
  { BundleId: 'bundle_7', CPU: 4, Memory: 16, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 405 } } },
  { BundleId: 'bundle_8', CPU: 4, Memory: 16, BundleSalesState: 'AVAILABLE', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 540 } } },
  // 无库存的套餐
  { BundleId: 'bundle_9', CPU: 2, Memory: 1, BundleSalesState: 'SOLD_OUT', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 40 } } },
  { BundleId: 'bundle_10', CPU: 2, Memory: 2, BundleSalesState: 'SOLD_OUT', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 55 } } },
  { BundleId: 'bundle_11', CPU: 2, Memory: 4, BundleSalesState: 'SOLD_OUT', Price: { InstancePrice: { Currency: 'CNY', OriginalPrice: 95 } } }
];

function testSelectionLogic() {
  console.log('🧪 测试套餐选择逻辑...\n');
  
  const availableBundles = mockBundles.filter(b => b.BundleSalesState === 'AVAILABLE');
  const unavailableBundles = mockBundles.filter(b => b.BundleSalesState !== 'AVAILABLE');
  
  console.log('📋 套餐列表：');
  console.log('='.repeat(80));
  
  // 显示可用套餐
  console.log('\n✅ 有库存的套餐：');
  availableBundles.forEach((bundle, index) => {
    const price = `CNY ${bundle.Price.InstancePrice.OriginalPrice}/月`;
    console.log(`  ${index + 1}. ${bundle.BundleId} - ${bundle.CPU}核${bundle.Memory}GB - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
  });
  
  // 显示无库存套餐
  console.log('\n❌ 无库存的套餐：');
  unavailableBundles.forEach((bundle, index) => {
    const price = `CNY ${bundle.Price.InstancePrice.OriginalPrice}/月`;
    console.log(`  ${availableBundles.length + index + 1}. ${bundle.BundleId} - ${bundle.CPU}核${bundle.Memory}GB - 价格: ${price} - 状态: ${bundle.BundleSalesState}`);
  });
  
  console.log('\n' + '='.repeat(80));
  
  // 测试选择逻辑
  console.log('\n🔍 测试选择逻辑：');
  
  // 测试选择有库存的套餐
  for (let i = 1; i <= availableBundles.length; i++) {
    let selectedBundle;
    if (i <= availableBundles.length) {
      selectedBundle = availableBundles[i - 1];
    } else {
      const unavailableIndex = i - availableBundles.length - 1;
      selectedBundle = unavailableBundles[unavailableIndex];
    }
    console.log(`  输入 ${i} -> 选择 ${selectedBundle.BundleId}`);
  }
  
  // 测试选择无库存的套餐
  for (let i = availableBundles.length + 1; i <= mockBundles.length; i++) {
    let selectedBundle;
    if (i <= availableBundles.length) {
      selectedBundle = availableBundles[i - 1];
    } else {
      const unavailableIndex = i - availableBundles.length - 1;
      selectedBundle = unavailableBundles[unavailableIndex];
    }
    console.log(`  输入 ${i} -> 选择 ${selectedBundle.BundleId}`);
  }
  
  console.log('\n✅ 测试完成！');
}

// 运行测试
if (require.main === module) {
  testSelectionLogic();
}

module.exports = { testSelectionLogic }; 