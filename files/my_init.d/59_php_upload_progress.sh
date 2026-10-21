#!/bin/sh
# Temporary surface reduction, NOT a confirmed fix for both PHP2Shell CVEs.
set -eu

found=0
for ini in /etc/php/*/*/php.ini; do
    [ -f "$ini" ] || continue
    found=1
    directory=$(dirname "$ini")
    mkdir -p "$directory/conf.d"
    cat > "$directory/conf.d/zzzz-upload-progress-security.ini" <<'INI'
; Temporary mitigation; install the vendor security update when available.
session.upload_progress.enabled = Off
INI
done
[ "$found" = 1 ] || { echo 'No PHP configuration found' >&2; exit 1; }

# INI_PERDIR can be overridden by .user.ini. Lock this at FPM pool level.
for pools in /etc/php/*/fpm/pool.d; do
    [ -d "$pools" ] || continue
    target="$pools/zzzz-upload-progress-security.conf"
    rm -f "$target"
    for config in "$pools"/*.conf; do
        [ "$config" != "$target" ] || continue
        [ -f "$config" ] || continue
        sed -n 's/^[[:space:]]*\[\([^]]*\)\][[:space:]]*$/\1/p' "$config"
    done | sort -u | while IFS= read -r pool; do
        [ "$pool" != global ] || continue
        printf '[%s]\nphp_admin_flag[session.upload_progress.enabled] = off\n' "$pool"
    done > "$target"
done
