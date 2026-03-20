# expo-openclaw-discovery

[![npm version](https://badge.fury.io/js/expo-openclaw-discovery.svg)](https://www.npmjs.com/package/expo-openclaw-discovery)
[![npm downloads](https://img.shields.io/npm/dm/expo-openclaw-discovery.svg)](https://www.npmjs.com/package/expo-openclaw-discovery)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](https://github.com/2winter-dev/expo-openclaw-discovery)

[English](README.md) | [简体中文](README.zh-CN.md)

OpenClaw Gateway Bonjour/mDNS discovery for Expo - Discover OpenClaw gateways on local network.

> **Note:** While this module is primarily built for discovering [OpenClaw](https://github.com/2winter-dev/openclaw) gateways, it can also be used to discover **any mDNS/Bonjour services** on your local network (e.g., `_http._tcp.`, `_printer._tcp.`, custom service types, etc.).

[⭐ Star us on GitHub](https://github.com/2winter-dev/expo-openclaw-discovery)

## Features

- 🔍 **mDNS/Bonjour Discovery**: Discover OpenClaw gateways on local network
- 📡 **Real-time Updates**: Get notified when services are discovered or lost
- 📱 **Cross-Platform**: Works on both iOS and Android
- 🎯 **OpenClaw Optimized**: Pre-configured for OpenClaw gateway discovery
- ⚡ **Type-Safe**: Full TypeScript support
- 🛠️ **Easy Integration**: Simple API with event-based notifications

## Installation

```bash
npm install expo-openclaw-discovery
# or
yarn add expo-openclaw-discovery
# or
npx expo install expo-openclaw-discovery
```

## Requirements

- `expo-modules-core` >= 0.4.0
- React Native >= 0.60.0
- Expo SDK >= 40

## Usage

### Basic Discovery

```typescript
import {
  startOpenClawDiscovery,
  stopOpenClawDiscovery,
  addOpenClawDiscoveryListener,
  isOpenClawDiscoveryAvailable
} from 'expo-openclaw-discovery';

// Check if discovery module is available
if (isOpenClawDiscoveryAvailable()) {
  // Start discovery with default settings
  startOpenClawDiscovery();

  // Listen for discovered services
  const serviceSubscription = addOpenClawDiscoveryListener('onService', (service) => {
    console.log('Service discovered:', service);
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

  // Listen for lost services
  const lostSubscription = addOpenClawDiscoveryListener('onServiceLost', (service) => {
    console.log('Service lost:', service);
    // service: { name: string; type?: string }
  });

  // Listen for errors
  const errorSubscription = addOpenClawDiscoveryListener('onError', (error) => {
    console.error('Discovery error:', error);
    // error: { message: string }
  });

  // Stop discovery when done
  // stopOpenClawDiscovery();

  // Clean up listeners
  // serviceSubscription.remove();
  // lostSubscription.remove();
  // errorSubscription.remove();
}
```

### Custom Service Type

```typescript
import { startOpenClawDiscovery } from 'expo-openclaw-discovery';

// Start discovery with custom service type
startOpenClawDiscovery({
  serviceType: '_http._tcp.',
  domain: 'local.'
});
```

### Advanced Usage with React Hooks

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
      setError('Discovery module not available');
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

    // Start discovery
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

// Usage in component
function GatewayDiscovery() {
  const { services, isScanning, error } = useOpenClawDiscovery();

  return (
    <View>
      <Text>Status: {isScanning ? 'Scanning...' : 'Stopped'}</Text>
      {error && <Text>Error: {error}</Text>}
      {services.map((service) => (
        <View key={service.name}>
          <Text>Name: {service.name}</Text>
          <Text>Host: {service.host}</Text>
          <Text>Port: {service.port}</Text>
        </View>
      ))}
    </View>
  );
}
```

## API Reference

### `isOpenClawDiscoveryAvailable(): boolean`

Check if the discovery module is available on the current platform.

### `startOpenClawDiscovery(options?: { serviceType?: string; domain?: string }): void`

Start discovering OpenClaw gateways.

**Parameters:**
- `options.serviceType` (optional): The service type to discover. Default: `_openclaw-gw._tcp.`
- `options.domain` (optional): The domain to search. Default: `local.`

### `stopOpenClawDiscovery(): void`

Stop discovering services.

### `addOpenClawDiscoveryListener(eventName: string, listener: (payload: any) => void): { remove: () => void }`

Add a listener for discovery events.

**Events:**
- `'onService'`: Service discovered. Payload: `OpenClawDiscoveredService`
- `'onServiceLost'`: Service lost. Payload: `{ name: string; type?: string }`
- `'onError'`: Error occurred. Payload: `{ message: string }`

**Returns:** A subscription object with a `remove()` method.

## Type Definitions

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

## Platform Notes

### iOS

- Uses native NSNetService API for Bonjour discovery
- Supports all standard mDNS service types
- Automatic service resolution

### Android

- Uses Android NsdManager for mDNS discovery
- Supports all standard mDNS service types
- Automatic service resolution

## OpenClaw Gateway Discovery

This module is optimized for discovering OpenClaw gateways:

- **Default Service Type**: `_openclaw-gw._tcp.`
- **Default Domain**: `local.`
- **Auto-Resolution**: Automatically resolves host and port

When an OpenClaw gateway is discovered, you'll receive:
- Gateway name
- Host address (IP)
- Port number
- TXT records (if available)

## Troubleshooting

### No Services Found

- Ensure your device and OpenClaw gateway are on the same network
- Check that the gateway is advertising via mDNS/Bonjour
- Try using a different service type if needed

### Discovery Not Working

- Ensure you have the necessary permissions
- On iOS, ensure Local Network Usage is enabled in Info.plist
- On Android, ensure you have the necessary permissions in AndroidManifest.xml

## Star History

<a href="https://www.star-history.com/?type=date&repos=2winter-dev%2Fexpo-openclaw-discovery">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=2winter-dev/expo-openclaw-discovery&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=2winter-dev/expo-openclaw-discovery&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=2winter-dev/expo-openclaw-discovery&type=date&legend=top-left" />
 </picture>
</a>

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Related Projects

- [OpenClaw](https://github.com/2winter-dev/openclaw) - AI Gateway
- [iClaw](https://github.com/2winter-dev/open-iClaw-app) - Mobile companion app for OpenClaw
- [expo-openclaw-ws](https://github.com/2winter-dev/expo-openclaw-ws) - OpenClaw WebSocket module
