ARG BASE_IMAGE=docker.hypernode.com/byteinternet/hypernode-buster-docker-php83-mysql80@sha256:fb866fd3a3904624aad1109e397a333e14e1230c9a8850d437b0e11d3330d626
FROM ${BASE_IMAGE} AS builder
USER root
# Buster security packages are archived. Keep signature verification enabled.
RUN sed -i 's|http://security.debian.org|http://archive.debian.org/debian-security|' /etc/apt/sources.list.d/hypernode.sources \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends make gcc pkg-config libxml2-dev libpcre2-dev libssl-dev libsodium-dev libargon2-dev zlib1g-dev
ARG PHP_BRANCH=8.3
ARG PATCH_PHP_VERSION=8.3.36
ARG PATCH_PHP_SHA256=dd54693aa334c5c4d72e9aee96b082c2473750a18a6c1d105789c93a3b1692fd
COPY security/rebuild-hypernode-php.sh /tmp/rebuild-hypernode-php.sh
RUN sh /tmp/rebuild-hypernode-php.sh

FROM ${BASE_IMAGE}
ARG PHP_BRANCH=8.3
ARG PATCH_PHP_VERSION=8.3.36
COPY --from=builder /opt/qualide/ /opt/qualide/
COPY --from=builder /usr/bin/php${PHP_BRANCH} /usr/bin/php${PHP_BRANCH}
COPY --from=builder /usr/sbin/php-fpm${PHP_BRANCH} /usr/sbin/php-fpm${PHP_BRANCH}
COPY --from=builder /usr/lib/php/ /usr/lib/php/
COPY --from=builder /etc/php/ /etc/php/
COPY files/my_init.d/59_php_upload_progress.sh /etc/my_init.d/59_php_upload_progress.sh
COPY security/58_verify_patched_php.sh /etc/my_init.d/58_verify_patched_php.sh
RUN chmod 755 /etc/my_init.d/59_php_upload_progress.sh \
    /etc/my_init.d/58_verify_patched_php.sh \
    && /etc/my_init.d/59_php_upload_progress.sh \
    && test "$(/usr/bin/php${PHP_BRANCH} -r 'echo PHP_VERSION;')" = "$PATCH_PHP_VERSION"
