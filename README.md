# Qualide Hypernode PHP security fork

Fork of ByteInternet/hypernode-docker. The original public Dockerfile only wraps
an upstream image; our Dockerfile builds supported PHP core from checksum-verified
PHP.net source and checks loaded-extension parity and FPM configuration.

Status: candidate builds, not approved for production. Existing sites stay offline.

Default build: PHP 8.3.36 on the pinned PHP 8.3/MySQL 8.0 Hypernode image:

```sh
docker build --platform linux/amd64 -t qualide/hypernode-php83:8.3.36-source .
```

PHP 8.2 build:

```sh
docker build --platform linux/amd64 \
 --build-arg BASE_IMAGE=docker.hypernode.com/byteinternet/hypernode-buster-docker-php82-mysql80@sha256:fa7cf4f3bc2a0889171bc9352ed607b833272cfabc4fb853dd2812a0bd73d24f \
 --build-arg PHP_BRANCH=8.2 --build-arg PATCH_PHP_VERSION=8.2.35 \
 --build-arg PATCH_PHP_SHA256=5737b98601fe5ab1b8c5db0c82ed3158acb9283ed3081ffe2faffb9ac81455e6 \
 -t qualide/hypernode-php82:8.2.35-source .
```

Only the selected PHP branch is rebuilt. Other vendor PHP versions remain old:
do not select or expose their FPM workers. Runtime tests and configuration of the
actual project image are required before any service can be restored. Buster is
an old OS; this PHP update does not constitute a complete OS security upgrade.

No deployment, public port publication, or production data access occurs during
these builds. Signature verification remains enabled for archived apt packages.
