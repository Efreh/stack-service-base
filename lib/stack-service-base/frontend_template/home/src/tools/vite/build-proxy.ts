import type { ProxyOptions } from 'vite';
import { normalizePathPrefix } from './path-prefix';

const DEFAULT_PROXY_OPTIONS: ProxyOptions = {
  cookieDomainRewrite: '',
  secure: true,
  changeOrigin: true
};

export type ProxyRuleConfig = {
  targetEnv: string;
  secure?: boolean;
  changeOrigin?: boolean;
  ws?: boolean;
  pathRewrite?: Record<string, string>;
};

export function buildProxy(
  env: Record<string, string>,
  rules: Record<string, ProxyRuleConfig>
): Record<string, ProxyOptions> {
  const proxy: Record<string, ProxyOptions> = {};
  const pathPrefix = normalizePathPrefix(env.PATH_PREFIX);

  for (const [context, rule] of Object.entries(rules)) {
    const target = env[rule.targetEnv];
    if (!target) continue;

    proxy[context] = createProxyOptions(target, rule);
    if (pathPrefix) proxy[`${pathPrefix}${context}`] = createProxyOptions(target, rule, pathPrefix);
  }

  return proxy;
}

function createProxyOptions(target: string, rule: ProxyRuleConfig, pathPrefix = ''): ProxyOptions {
  const { pathRewrite, targetEnv: _targetEnv, ...overrides } = rule;
  const shouldRewrite = Boolean(pathPrefix || pathRewrite);

  return {
    target,
    ...DEFAULT_PROXY_OPTIONS,
    ...overrides,
    ...(shouldRewrite ? { rewrite: (path: string) => rewritePath(stripPathPrefix(path, pathPrefix), pathRewrite) } : {})
  };
}

function stripPathPrefix(path: string, pathPrefix: string): string {
  if (!pathPrefix || !path.startsWith(`${pathPrefix}/`)) return path;
  return path.slice(pathPrefix.length) || '/';
}

function rewritePath(path: string, pathRewrite?: Record<string, string>): string {
  if (!pathRewrite) return path;

  for (const [from, to] of Object.entries(pathRewrite)) {
    const rewrittenPath = path.replace(new RegExp(from), to);
    if (rewrittenPath !== path) return rewrittenPath;
  }

  return path;
}
