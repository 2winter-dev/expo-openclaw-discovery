# expo-openclaw-discovery

[![npm version](https://badge.fury.io/js/expo-openclaw-discovery.svg)](https://www.npmjs.com/package/expo-openclaw-discovery)
[![npm downloads](https://img.shields.io/npm/dm/expo-openclaw-discovery.svg)](https://www.npmjs.com/package/expo-openclaw-discovery)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](https://github.com/2winter-dev/expo-openclaw-discovery)

[English](README.md) | [简体中文](README.zh-CN.md)

OpenClaw 网关的 Bonjour/mDNS 服务发现模块（适用于 Expo）- 在本地网络中发现 OpenClaw 网关。

[⭐ 在 GitHub 上给我们星标](https://github.com/2winter-dev/expo-openclaw-discovery)

## 特性

- 🔍 **mDNS/Bonjour 服务发现**：在本地网络中发现 OpenClaw 网关
- 📡 **实时更新**：当服务被发现或丢失时接收通知
- 📱 **跨平台**：同时支持 iOS 和 Android
- 🎯 **OpenClaw 优化**：专为 OpenClaw 网关发现预配置
- ⚡ **类型安全**：完整的 TypeScript 支持
- 🛠️ **易于集成**：简单的 API，基于事件的通知

## 安装

```bash
npm install expo-openclaw-discovery
# 或者
yarn add expo-openclaw-discovery
# 或者
npx expo install expo-openclaw-discovery
```

## 要求

- `expo-modules-core` >= 0.4.0
- React Native >= 0.60.0
- Expo SDK >= 40

## 使用方法

### 基本服务发现

```typescript
import {
  startOpenClawDiscovery,
  stopOpenClawDiscovery,
  addOpenClawDiscoveryListener,
  isOpenClawDiscoveryAvailable
} from 'expo-openclaw-discovery';

// 检查服务发现模块是否可用
if (isOpenClawDiscoveryAvailable()) {
  // 使用默认设置开始发现
  startOpenClawDiscovery();

  // 监听发现的服务
  const serviceSubscription = addOpenClawDiscoveryListener('onService', (service) => {
    console.log('发现服务:', service);
    // service: {
    //   name: string;
    //   type?: string;
    //   domain?: string;
    //   host?: string;
    //   port?: number;
    //   addresses?: string[];
    //   txt?: Record<string, string>;
    // }
  });

  // 监听丢失的服务
  const lostSubscription = addOpenClawDiscoveryListener('onServiceLost', (service) => {
    console.log('服务丢失:', service);
    // service: { name: string; type?: string }
  });

  // 监听错误
  const errorSubscription = addOpenClawDiscoveryListener('onError', (error) => {
    console.error('发现错误:', error);
    // error: { message: string }
  });

  // 完成后停止发现
  // stopOpenClawDiscovery();

  // 清理监听器
  // serviceSubscription.remove();
  // lostSubscription.remove();
  // errorSubscription.remove();
}
```

### 自定义服务类型

```typescript
import { startOpenClawDiscovery } from 'expo-openclaw-discovery';

// 使用自定义服务类型开始发现
startOpenClawDiscovery({
  serviceType: '_http._tcp.',
  domain: 'local.'
});
```

### 使用 React Hooks 的高级用法

```typescript
import { useEffect, useState, useCallback } from 'react';
import {
  startOpenClawDiscovery,
  stopOpenClawDiscovery,
  addOpenClawDiscoveryListener,
  isOpenClawDiscoveryAvailable
} from 'expo-openclaw-discovery';

interface DiscoveredService {
  name: string;
  type?: string;
  domain?: string;
  host?: string;
  port?: number;
  addresses?: string[];
  txt?: Record<string, string>;
}

function useOpenClawDiscovery(options?: { serviceType?: string; domain?: string }) {
  const [services, setServices] = useState<DiscoveredService[]>([]);
  const [isScanning, setIsScanning] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpenClawDiscoveryAvailable()) {
      setError('服务发现模块不可用');
      return;
    }

    const serviceSub = addOpenClawDiscoveryListener('onService', (service) => {
      setServices((prev) => {
        const existing = prev.findIndex((s) => s.name === service.name);
        if (existing >= 0) {
          const updated = [...prev];
          updated[existing] = service;
          return updated;
        }
        return [...prev, service];
      });
    });

    const lostSub = addOpenClawDiscoveryListener('onServiceLost', (service) => {
      setServices((prev) => prev.filter((s) => s.name !== service.name));
    });

    const errorSub = addOpenClawDiscoveryListener('onError', (err) => {
      setError(err.message);
    });

    // 开始发现
    startOpenClawDiscovery(options);
    setIsScanning(true);

    return () => {
      stopOpenClawDiscovery();
      setIsScanning(false);
      serviceSub.remove();
      lostSub.remove();
      errorSub.remove();
    };
  }, [options]);

  return { services, isScanning, error };
}

// 在组件中使用
function GatewayDiscovery() {
  const { services, isScanning, error } = useOpenClawDiscovery();

  return (
    <View>
      <Text>状态: {isScanning ? '扫描中...' : '已停止'}</Text>
      {error && <Text>错误: {error}</Text>}
      {services.map((service) => (
        <View key={service.name}>
          <Text>名称: {service.name}</Text>
          <Text>主机: {service.host}</Text>
          <Text>端口: {service.port}</Text>
        </View>
      ))}
    </View>
  );
}
```

## API 参考

### `isOpenClawDiscoveryAvailable(): boolean`

检查当前平台的服务发现模块是否可用。

### `startOpenClawDiscovery(options?: { serviceType?: string; domain?: string }): void`

开始发现 OpenClaw 网关。

**参数：**
- `options.serviceType`（可选）：要发现的服务类型。默认值：`_openclaw-gw._tcp.`
- `options.domain`（可选）：要搜索的域。默认值：`local.`

### `stopOpenClawDiscovery(): void`

停止发现服务。

### `addOpenClawDiscoveryListener(eventName: string, listener: (payload: any) => void): { remove: () => void }`

添加服务发现事件的监听器。

**事件：**
- `'onService'`：服务被发现。载荷：`OpenClawDiscoveredService`
- `'onServiceLost'`：服务丢失。载荷：`{ name: string; type?: string }`
- `'onError'`：发生错误。载荷：`{ message: string }`

**返回：** 一个带有 `remove()` 方法的订阅对象。

## 类型定义

```typescript
export type OpenClawDiscoveredService = {
  name: string;
  type?: string;
  domain?: string;
  host?: string;
  port?: number;
  addresses?: string[];
  txt?: Record<string, string>;
};
```

## 平台说明

### iOS

- 使用原生 NSNetService API 进行 Bonjour 服务发现
- 支持所有标准 mDNS 服务类型
- 自动服务解析

### Android

- 使用 Android NsdManager 进行 mDNS 服务发现
- 支持所有标准 mDNS 服务类型
- 自动服务解析

## OpenClaw 网关发现

此模块专为发现 OpenClaw 网关而优化：

- **默认服务类型**：`_openclaw-gw._tcp.`
- **默认域**：`local.`
- **自动解析**：自动解析主机和端口

当发现 OpenClaw 网关时，您将收到：
- 网关名称
- 主机地址（IP）
- 端口号
- TXT 记录（如果可用）

## 故障排除

### 未找到服务

- 确保您的设备和 OpenClaw 网关在同一网络上
- 检查网关是否通过 mDNS/Bonjour 进行广播
- 如有必要，尝试使用不同的服务类型

### 服务发现不工作

- 确保您具有必要的权限
- 在 iOS 上，确保在 Info.plist 中启用了本地网络使用
- 在 Android 上，确保您在 AndroidManifest.xml 中具有必要的权限

## Star History

<a href="https://www.star-history.com/?type=date&repos=2winter-dev%2Fexpo-openclaw-discovery">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=2winter-dev/expo-openclaw-discovery&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=2winter-dev/expo-openclaw-discovery&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=2winter-dev/expo-openclaw-discovery&type=date&legend=top-left" />
 </picture>
</a>

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

MIT

## 相关项目

- [OpenClaw](https://github.com/2winter-dev/openclaw) - AI 网关
- [iClaw](https://github.com/2winter-dev/open-iClaw-app) - OpenClaw 的移动伴侣应用
- [expo-openclaw-ws](https://github.com/2winter-dev/expo-openclaw-ws) - OpenClaw WebSocket 模块
