## Nginx Release

To vendor nginx package into your release, run:

```
$ git clone https://github.com/bosh-packages/nginx-release
$ cd ~/workspace/your-release
$ bosh vendor-package nginx-1.14 ~/workspace/nginx-release
```

The above code will add `nginx-1.14` to `your-release` and introduce a `spec.lock`.

Included packages:

- nginx-1.12 which includes:
	- nginx-1.12.x.tar.gz
	- headers-more-nginx-module-0.30.tar.gz
	- pcre-8.x.tar.gz
	- nginx-upload-module-2.2.tar.gz
	- nginx-upload-module.patch
- nginx-1.14 which includes:
	- nginx-1.14.x.tar.gz
	- pcre-8.x.tar.gz
	- headers-more-nginx-module-0.30.tar.gz
	- nginx-upload-module-2.2.tar.gz
	- nginx-upload-module.patch

To use `nginx-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/nginx-1.14/bosh/runtime.env
source /var/vcap/packages/your-package/bosh/runtime.env
nginx ...
```

See [jobs/nginx-1.14-test](jobs/nginx-1.14-test) for example.

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## Verify blobs

```
$ mkdir tmp
$ gpg --homedir tmp --import keys/*
$ gpg --homedir tmp --verify blobs/nginx-1.12.2.tar.gz.asc
$ gpg --homedir tmp --verify blobs/nginx-1.14.0.tar.gz.asc
$ gpg --homedir tmp --verify blobs/pcre-8.41.tar.gz.sig
$ gpg --homedir tmp --verify blobs/pcre-8.42.tar.gz.sig
```
