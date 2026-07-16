import type { Plugin } from 'vite';
import { buildRuntimeConfigFromEnv } from './runtime-config';
import { normalizePathPrefix } from './path-prefix';

export function runtimeConfigDevPlugin(env: Record<string, string>): Plugin {
  const pathPrefix = normalizePathPrefix(env.PATH_PREFIX);
  const runtimeConfigPath = `${pathPrefix}/runtime-config.js`;

  return {
    name: 'runtime-config-dev',
    configureServer(server) {
      server.middlewares.use((request, response, next) => {
        const requestPath = request.url?.split('?', 1)[0];

        if (requestPath !== runtimeConfigPath) {
          next();
          return;
        }

        const runtimeConfig = buildRuntimeConfigFromEnv(env);
        response.setHeader('Content-Type', 'application/javascript; charset=utf-8');
        response.setHeader('Cache-Control', 'no-store');
        response.end(`window.__APP_CONFIG__ = ${JSON.stringify(runtimeConfig)};`);
      });
    }
  };
}
