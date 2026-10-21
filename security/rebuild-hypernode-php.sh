#!/bin/sh
set -eux
# Build a supported PHP core against the pinned Hypernode userspace. Shared
# extension ABI and full loaded-module parity are checked before image approval.
: "${PATCH_PHP_VERSION:?}" "${PATCH_PHP_SHA256:?}" "${PHP_BRANCH:?}"
old="/usr/bin/php${PHP_BRANCH}"
api=$($old -i | awk '/^PHP Extension =>/ {print $4; exit}')
$old -m | sort > /tmp/modules-before.txt
curl -fsSL --retry 3 "https://www.php.net/distributions/php-${PATCH_PHP_VERSION}.tar.xz" -o /tmp/php.tar.xz
printf '%s  %s\n' "$PATCH_PHP_SHA256" /tmp/php.tar.xz | sha256sum -c -
mkdir /tmp/php-source
tar -xJf /tmp/php.tar.xz -C /tmp/php-source --strip-components=1
cd /tmp/php-source
./configure --prefix="/opt/qualide/php/$PHP_BRANCH" \
  --with-config-file-path="/etc/php/$PHP_BRANCH/cli" \
  --with-config-file-scan-dir="/etc/php/$PHP_BRANCH/cli/conf.d" \
  --disable-all --enable-cli --disable-cgi --disable-phpdbg \
  --enable-fpm --with-fpm-user=app --with-fpm-group=app \
  --enable-filter --enable-libxml --with-openssl --enable-pcntl \
  --enable-session --with-sodium --with-zlib --with-password-argon2 \
  --enable-opcache=shared
make -j4
make install
install -m755 "sapi/cli/php" "$old"
install -m644 modules/opcache.so "/usr/lib/php/$api/opcache.so"
printf '#!/bin/sh\nexport PHP_INI_SCAN_DIR=/etc/php/%s/fpm/conf.d\nexec /opt/qualide/php/%s/sbin/php-fpm -c /etc/php/%s/fpm/php.ini -y /etc/php/%s/fpm/php-fpm.conf "$@"\n' "$PHP_BRANCH" "$PHP_BRANCH" "$PHP_BRANCH" "$PHP_BRANCH" > "/usr/sbin/php-fpm$PHP_BRANCH"
chmod 755 "/usr/sbin/php-fpm$PHP_BRANCH"
# Debian module INIs use relative paths; preserve their vendor extension ABI path.
for sapi in cli fpm; do
  printf 'extension_dir=/usr/lib/php/%s\nsession.upload_progress.enabled=Off\n' "$api" > "/etc/php/$PHP_BRANCH/$sapi/conf.d/00-qualide-security.ini"
done
$old -m | sort > /tmp/modules-after.txt
diff -u /tmp/modules-before.txt /tmp/modules-after.txt
test "$($old -r 'echo PHP_VERSION;')" = "$PATCH_PHP_VERSION"
"/usr/sbin/php-fpm$PHP_BRANCH" -t
rm -rf /tmp/php-source /tmp/php.tar.xz
