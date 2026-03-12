#!/usr/bin/env bash
set -eu -o pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
REPO_PARENT="$( cd "${REPO_ROOT}/.." && pwd )"

if [[ -n "${DEBUG:-}" ]]; then
  set -x
  export DEBUG="${DEBUG}"
  export BOSH_LOG_LEVEL=debug
  export BOSH_LOG_PATH="${BOSH_LOG_PATH:-${REPO_PARENT}/bosh-debug.log}"
fi

echo "Starting Docker and Director"
source start-bosh
source /tmp/local-bosh/director/env

echo "Upload stemcell"
bosh -n upload-stemcell stemcell/stemcell.tgz

cd "${REPO_ROOT}" # required to deploy source release

echo "Deploy nginx"
bosh -n -d test deploy \
  --var=stemcell_os="${STEMCELL_OS}" \
  manifests/test.yml

echo "Run test errand"
bosh -n -d test run-errand nginx-test
