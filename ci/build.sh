#!/bin/bash

set -e -o pipefail

cd nginx-release

echo "Starting Docker and Director"
source start-bosh
source /tmp/local-bosh/director/env

echo "Run tests"
pushd tests
 ./run.sh
popd

echo "Issue new release"
./ci/finalize.sh

echo "Concourse output"
cd ..
git clone nginx-release nginx-release-out
