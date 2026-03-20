import { requireNativeModule } from 'expo-modules-core';

type NativeModule = {
  start: (serviceType?: string, domain?: string) => void;
  stop: () => void;
  addListener: (
    eventName: 'onService' | 'onServiceLost' | 'onError',
    listener: (payload: any) => void
  ) => { remove: () => void };
};

let nativeModule: NativeModule | null = null;

try {
  nativeModule = requireNativeModule<NativeModule>('OpenClawDiscovery');
} catch {
  nativeModule = null;
}

export type OpenClawDiscoveredService = {
  name: string;
  type?: string;
  domain?: string;
  host?: string;
  port?: number;
  addresses?: string[];
  txt?: Record<string, string>;
};

export type OpenClawServiceLostEvent = {
  name: string;
  type?: string;
};

export type OpenClawErrorEvent = {
  message: string;
};

export function isOpenClawDiscoveryAvailable() {
  return Boolean(nativeModule);
}

export function startOpenClawDiscovery(options?: { serviceType?: string; domain?: string }) {
  if (!nativeModule) return;
  nativeModule.start(options?.serviceType, options?.domain);
}

export function stopOpenClawDiscovery() {
  if (!nativeModule) return;
  nativeModule.stop();
}

export function addOpenClawDiscoveryListener(
  eventName: 'onService',
  listener: (payload: OpenClawDiscoveredService) => void
): { remove: () => void };
export function addOpenClawDiscoveryListener(
  eventName: 'onServiceLost',
  listener: (payload: OpenClawServiceLostEvent) => void
): { remove: () => void };
export function addOpenClawDiscoveryListener(
  eventName: 'onError',
  listener: (payload: OpenClawErrorEvent) => void
): { remove: () => void };
export function addOpenClawDiscoveryListener(
  eventName: 'onService' | 'onServiceLost' | 'onError',
  listener: (payload: any) => void
) {
  return nativeModule?.addListener(eventName, listener) ?? { remove: () => {} };
}
