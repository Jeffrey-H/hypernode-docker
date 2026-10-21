#!/bin/sh
set -eu
branch=$(jq -er '.php.version | tostring' /etc/hypernode/magweb.json)
case "$branch" in
  8.2) minimum=8.2.35 ;;
  8.3) minimum=8.3.36 ;;
  *) echo "Unsupported PHP branch $branch: refusing to start Hypernode" >&2; exit 1 ;;
esac
"/usr/bin/php$branch" -r 'exit(version_compare(PHP_VERSION, $argv[1], ">=") ? 0 : 1);' "$minimum" || {
  echo "Selected PHP $branch is not patched; refusing to start Hypernode" >&2
  exit 1
}
