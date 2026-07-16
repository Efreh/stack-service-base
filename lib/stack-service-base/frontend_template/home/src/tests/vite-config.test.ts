import { describe, expect, it } from 'vitest';
import { buildBase } from '../vite.config';

describe('buildBase', () => {
  it('keeps the runtime placeholder in a container build', () => {
    expect(buildBase('build', 'production', '/team/ui')).toBe('/__PATH_PREFIX__/');
  });

  it('uses the configured prefix in a local production preview', () => {
    expect(buildBase('build', 'preview', '/team/ui')).toBe('/team/ui/');
  });

  it('uses the configured prefix in development', () => {
    expect(buildBase('serve', 'development', '/team/ui')).toBe('/team/ui/');
  });
});
