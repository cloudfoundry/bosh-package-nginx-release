## Nginx Release

To vendor nginx package into your release, run:

```
$ git clone https://github.com/bosh-packages/nginx-release
$ cd ~/workspace/your-release
$ bosh vendor-package nginx ~/workspace/nginx-release
```

The above code will add `nginx` to `your-release` and introduce a `spec.lock`.

Included packages:

- nginx which includes:
	- nginx-1.*.tar.gz (which will be the latest mainline version of nginx)
	- pcre-8.45.tar.gz
	- headers-more-nginx-module-0.33.tar.gz
	- nginx-upload-module-2.3.0.tar.gz
	- ngx_http_hmac_secure_link_module-0.3.tar.gz

To use the `nginx` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/nginx/bosh/runtime.env
source /var/vcap/packages/your-package/bosh/runtime.env
nginx ...
```

See [jobs/nginx-test](jobs/nginx-test) for example.

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## Updating nginx

When determining the latest version of nginx, use the _mainline_ branch, not the
_stable_ branch, at <http://nginx.org/en/download.html>.

Follow the instructions below, and make sure to set `VERSION` to the newest
nginx release, and `OLD_VERSION` to the current BOSH release's nginx version:

```bash
export OLD_VERSION=1.17.3
export VERSION=1.21.3
  # Download & verify nginx
pushd ~/workspace/nginx-release
mkdir blobs
pushd blobs
  # download blobs & signatures to blobs/
curl -OL http://nginx.org/keys/nginx_signing.key
curl -OL http://nginx.org/keys/mdounin.key
curl -OL http://nginx.org/download/nginx-$VERSION.tar.gz
curl -OL http://nginx.org/download/nginx-$VERSION.tar.gz.asc
mkdir /tmp/$$
chmod 700 /tmp/$$
gpg2 --homedir /tmp/$$ --import nginx_signing.key # The canonical signing key
gpg2 --homedir /tmp/$$ --import mdounin.key # Sometimes Maxim Dounin signs with his own key
gpg2 --homedir /tmp/$$ --verify nginx-$VERSION.tar.gz.asc
popd
  # Prepare the BOSH release
git pull -r --autostash
git mv jobs/nginx-${OLD_VERSION}-test jobs/nginx-${VERSION}-test
git mv packages/nginx-${OLD_VERSION} packages/nginx-${VERSION}
find packages/nginx-${VERSION} jobs/nginx-${VERSION}-test manifests/ tests/ README.md \
  -type f -print0 | \
  xargs -0 perl -pi -e \
  "s/nginx-${OLD_VERSION}/nginx-${VERSION}/g"
bosh add-blob \
  blobs/nginx-${VERSION}.tar.gz \
  nginx-${VERSION}.tar.gz
bosh add-blob \
  blobs/nginx-${VERSION}.tar.gz.asc \
  nginx-${VERSION}.tar.gz.asc
vim config/blobs.yml
  # delete `nginx/nginx-${OLD_VERSION}.tar.gz` stanza
bosh create-release --force
export BOSH_ENVIRONMENT=vbox
bosh upload-release
bosh -n -d test \
  deploy manifests/test.yml --recreate
bosh -d test run-errand nginx-${VERSION}-test # is final output "Succeeded"?
```

Configure `config/private.yml`, (hint: LastPass, "CF Bosh Packages"), then:

```bash
bosh upload-blobs
```

Commit & push:

```bash
git add -p
git ci -m"Bump nginx ${OLD_VERSION} → ${VERSION}"
git push
```

Trigger new build:
<https://ci.bosh-ecosystem.cf-app.com/teams/main/pipelines/nginx-release>

### Optional: Bumping PCRE

If you're updating PCRE as well as nginx, here are some commands to insert in
the appropriate places ("appropriate" being an exercise left to the reader).

```
gpg2 --homedir /tmp/$$ --keyserver keyserver.ubuntu.com --recv-key \
        45F68D54BBE23FB3039B46E59766E084FB0F43D8 # Philip Hazel's public GPG key for pcre (https://www.pcre.org/).
gpg2 --homedir /tmp/$$ --verify pcre-8.*.tar.gz.sig
find packages/nginx-${VERSION} -type f -print0 | \
  xargs -0 perl -pi -e \
  "s/pcre-8.42/pcre-8.45/g"
bosh add-blob \
  blobs/pcre-8.45.tar.gz \
  pcre-8.45.tar.gz
bosh add-blob \
  blobs/pcre-8.45.tar.gz.sig \
  pcre-8.45.tar.gz.sig
```

### Optional: Sources

- nginx-upload-module: <https://github.com/vkholodkov/nginx-upload-module/archive/refs/tags/2.3.0.tar.gz>
- headers-more-nginx-module: <https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.33.tar.gz>
- ngx_http_hmac_secure_link_module: <https://github.com/nginx-modules/ngx_http_hmac_secure_link_module/archive/refs/tags/0.3.tar.gz>

### Addenda

A copy of the PGP signing keys is available in `keys/` in the event that a key
server is down or that a key's URL has changed.
