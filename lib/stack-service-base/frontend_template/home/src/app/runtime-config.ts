import { normalizePathPrefix } from '../tools/vite/path-prefix';
import type { RuntimeConfig } from './runtime-config.types';

declare global {
  interface Window {
    __APP_CONFIG__?: RuntimeConfig;
  }
}

const runtimeConfig = window.__APP_CONFIG__ ?? {};
const pathPrefix = normalizePathPrefix(runtimeConfig.PATH_PREFIX);

export const environment = Object.freeze({
  serviceName: '${service_name}',
  pathPrefix,
  apiBaseUrl: runtimeConfig.API_BASE_URL?.trim() || joinPath(pathPrefix, 'api'),
  logLevel: runtimeConfig.LOG_LEVEL?.trim() || 'info'
});

function joinPath(prefix: string, path: string): string {
  return `${prefix}/${path}`.replace(/\/+/gu, '/');
}
