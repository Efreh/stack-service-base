import { describe, expect, it } from 'vitest';
import { buildProxy } from '../tools/vite/build-proxy';

const rules = {
  '/api': {
    targetEnv: 'BACKEND_URL',
    secure: true,
    changeOrigin: true,
    ws: true
  }
};

describe('development proxy', () => {
  it('builds root and prefixed routes for the configured backend', () => {
    const proxy = buildProxy(
      { PATH_PREFIX: '/portal', BACKEND_URL: 'https://api.example.com' },
      rules
    );

    expect(proxy['/api']?.target).toBe('https://api.example.com');
    expect(proxy['/portal/api']?.target).toBe('https://api.example.com');
    expect(proxy['/portal/api']?.rewrite?.('/portal/api/status')).toBe('/api/status');
  });

  it('does not create routes when the backend is not configured', () => {
    expect(buildProxy({}, rules)).toEqual({});
  });
});
