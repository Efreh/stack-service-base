import { describe, expect, it } from 'vitest';
import { normalizePathPrefix, pathPrefixBase } from '../tools/vite/path-prefix';

describe('path prefix', () => {
  it('normalizes empty and nested prefixes', () => {
    expect(normalizePathPrefix(undefined)).toBe('');
    expect(normalizePathPrefix(' /team/ui/ ')).toBe('/team/ui');
    expect(pathPrefixBase('/team/ui')).toBe('/team/ui/');
  });

  it.each(['/api', '/assets', '/healthcheck', '/team//ui', '/../admin', '/admin?debug=true'])(
    'rejects an unsafe or runtime-reserved prefix: %s',
    (pathPrefix) => {
      expect(() => normalizePathPrefix(pathPrefix)).toThrow();
    }
  );
});
