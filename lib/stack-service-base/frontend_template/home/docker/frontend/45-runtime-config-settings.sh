#!/bin/sh
set -eu

compiled_app_dir=${COMPILED_APP_DIR:-/usr/share/nginx/html}
output="$compiled_app_dir/runtime-config.js"
temporary_output="$output.tmp"
path_prefix=$(printf '%s' "${PATH_PREFIX:-}" |
  sed -E 's#^[[:space:]]+|[[:space:]]+$##g; s#^/+##; s#/+$##')

if [ -n "$path_prefix" ]; then
  path_prefix="/$path_prefix"
fi

{
  printf 'window.__APP_CONFIG__ = '
  jq -cn \
    --arg pathPrefix "$path_prefix" \
    --arg apiBaseUrl "${API_BASE_URL:-}" \
    --arg logLevel "${LOG_LEVEL:-info}" \
    '{PATH_PREFIX: $pathPrefix, API_BASE_URL: $apiBaseUrl, LOG_LEVEL: $logLevel}'
  printf ';\n'
} > "$temporary_output"

mv "$temporary_output" "$output"
