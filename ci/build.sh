#!/bin/bash

set -e -o pipefail

cd nginx-release

echo "Starting Docker and Director"
source `which start-bosh` # source to load DOCKER_ env vars
source /tmp/local-bosh/director/env

echo "(debug) Starting Docker daemon and Director"
source ./ci/start-docker.sh
start_docker

echo "Docker env useful for copy-pasta during debugging"
env | grep DOCKER_ | xargs -n1 echo export

echo "Run tests"
pushd tests
 ./run.sh
popd

echo "Issue new release"
./ci/finalize.sh

echo "Concourse output"
cd ..
git clone nginx-release nginx-release-out

