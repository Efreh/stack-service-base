import type { RuntimeConfig } from '../../app/runtime-config.types';
import { normalizePathPrefix } from './path-prefix';

export function buildRuntimeConfigFromEnv(env: Record<string, string>): RuntimeConfig {
  return {
    PATH_PREFIX: normalizePathPrefix(env.PATH_PREFIX),
    API_BASE_URL: env.API_BASE_URL?.trim() ?? '',
    LOG_LEVEL: env.LOG_LEVEL?.trim() || 'info'
  };
}
