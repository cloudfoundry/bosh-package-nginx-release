## Nginx Release

To vendor nginx package into your release, run:

```
$ git clone https://github.com/bosh-packages/nginx-release
$ cd ~/workspace/your-release
$ bosh vendor-package nginx-1.17.3 ~/workspace/nginx-release
```

The above code will add `nginx-1.17.3` to `your-release` and introduce a `spec.lock`.

Included packages:

- nginx-1.17.3 which includes:
	- nginx-1.17.3.tar.gz
	- pcre-8.x.tar.gz
	- headers-more-nginx-module-0.30.tar.gz
	- nginx-upload-module-2.2.tar.gz
	- nginx-upload-module.patch

To use `nginx-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/nginx-1.17.3/bosh/runtime.env
source /var/vcap/packages/your-package/bosh/runtime.env
nginx ...
```

See [jobs/nginx-1.17.3-test](jobs/nginx-1.17.3-test) for example.

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## Updating this package

Only include the latest version of the package in this release. This includes
removing the old version from blobs, jobs, packages, and the manifest.

The current nginx blob was pulled from: http://nginx.org/en/download.html.

## Verify blobs

```
$ mkdir tmp
$ gpg --homedir tmp --import keys/*
$ gpg --homedir tmp --verify blobs/*.asc
$ gpg --homedir tmp --verify blobs/*.sig
```
