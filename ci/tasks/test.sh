#!/bin/bash

set -euxo pipefail

echo "Starting Docker and Director"
source start-bosh
source /tmp/local-bosh/director/env
bosh -n upload-stemcell stemcell/stemcell.tgz

cd nginx-release

echo "Run tests"

bosh -n -d test deploy ./manifests/test.yml

bosh -n -d test run-errand nginx-test
