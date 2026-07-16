#!/bin/sh
set -eu

compiled_app_dir=${COMPILED_APP_DIR:-/usr/share/nginx/html}
placeholder='/__PATH_PREFIX__/'
path_prefix=$(printf '%s' "${PATH_PREFIX:-}" |
  sed -E 's#^[[:space:]]+|[[:space:]]+$##g; s#^/+##; s#/+$##')

if [ -n "$path_prefix" ]; then
  replacement="/$path_prefix/"
else
  replacement='/'
fi

escaped_replacement=$(printf '%s' "$replacement" | sed -e 's/[\\&|]/\\&/g')

find "$compiled_app_dir" -type f \
  \( -name '*.html' -o -name '*.js' -o -name '*.css' -o -name '*.map' \) -print |
  while IFS= read -r file; do
    if grep -q "$placeholder" "$file"; then
      sed -i "s|$placeholder|$escaped_replacement|g" "$file"
    fi
  done

if find "$compiled_app_dir" -type f \
  \( -name '*.html' -o -name '*.js' -o -name '*.css' -o -name '*.map' \) \
  -exec grep -q "$placeholder" {} \; -print | grep -q .; then
  echo "PATH_PREFIX placeholder remains in compiled assets" >&2
  exit 1
fi
