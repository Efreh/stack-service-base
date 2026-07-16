import { ESLint } from 'eslint';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { normalizePathPrefix } from '../tools/vite/path-prefix';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');

describe('JavaScript support', () => {
  it('allows JavaScript modules to import TypeScript modules', () => {
    expect(normalizePathPrefix('/team/ui/')).toBe('/team/ui');
  });

  it('lints application JavaScript with browser globals', async () => {
    const eslint = new ESLint({ cwd: projectRoot });
    const [result] = await eslint.lintText(
      'document.body.dataset.path = window.location.pathname;',
      { filePath: resolve(projectRoot, 'app/javascript-support.js') }
    );

    expect(result.messages).toEqual([]);
  });
});
