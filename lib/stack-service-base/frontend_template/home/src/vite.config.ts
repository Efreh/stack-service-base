import { defineConfig, loadEnv } from 'vite';
import proxyRules from './proxy.config.json';
import { buildProxy } from './tools/vite/build-proxy';
import { runtimeConfigDevPlugin } from './tools/vite/runtime-config-dev-plugin';
import { pathPrefixBase } from './tools/vite/path-prefix';

const DEPLOY_PATH_PLACEHOLDER = '/__PATH_PREFIX__/';

export function buildBase(
  command: 'build' | 'serve',
  mode: string,
  pathPrefix: string | undefined
): string {
  const isContainerBuild = command === 'build' && mode !== 'preview';

  return isContainerBuild ? DEPLOY_PATH_PLACEHOLDER : pathPrefixBase(pathPrefix);
}

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, '.', '');

  return {
    base: buildBase(command, mode, env.PATH_PREFIX),
    plugins: [runtimeConfigDevPlugin(env)],
    build: {
      outDir: 'dist',
      emptyOutDir: true
    },
    server: {
      port: 3000,
      strictPort: true,
      open: false,
      proxy: buildProxy(env, proxyRules)
    },
    preview: {
      port: 3000,
      strictPort: true
    }
  };
});
