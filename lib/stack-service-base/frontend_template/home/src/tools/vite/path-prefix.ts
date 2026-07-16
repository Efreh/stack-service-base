const PATH_PREFIX_PATTERN = /^[A-Za-z0-9_/-]+$/u;
const RESERVED_PATH_PREFIXES = new Set(['/api', '/assets', '/healthcheck']);

export function normalizePathPrefix(value: string | undefined): string {
  const normalized = value?.trim().replace(/^\/+|\/+$/gu, '') ?? '';

  if (!normalized) {
    return '';
  }

  if (!PATH_PREFIX_PATTERN.test(normalized) || normalized.includes('//') || normalized.split('/').includes('..')) {
    throw new Error(`Invalid PATH_PREFIX: ${value}`);
  }

  const pathPrefix = `/${normalized}`;

  if (RESERVED_PATH_PREFIXES.has(pathPrefix)) {
    throw new Error(`PATH_PREFIX is reserved by the service runtime: ${pathPrefix}`);
  }

  return pathPrefix;
}

export function pathPrefixBase(value: string | undefined): string {
  const pathPrefix = normalizePathPrefix(value);
  return pathPrefix ? `${pathPrefix}/` : '/';
}
