import { describe, expect, it } from 'vitest';
import { buildRuntimeConfigFromEnv } from '../tools/vite/runtime-config';

describe('runtime config', () => {
  it('exposes only the documented browser-visible values', () => {
    const runtimeConfig = buildRuntimeConfigFromEnv({
      PATH_PREFIX: ' /team/ui/ ',
      API_BASE_URL: ' /team/ui/api ',
      LOG_LEVEL: ' debug ',
      BACKEND_URL: 'https://internal-api.example.com',
      AUTH_PASS: 'must-not-be-public'
    });

    expect(runtimeConfig).toEqual({
      PATH_PREFIX: '/team/ui',
      API_BASE_URL: '/team/ui/api',
      LOG_LEVEL: 'debug'
    });
    expect(JSON.stringify(runtimeConfig)).not.toContain('internal-api');
    expect(JSON.stringify(runtimeConfig)).not.toContain('must-not-be-public');
  });
});
