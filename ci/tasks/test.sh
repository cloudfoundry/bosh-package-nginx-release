#!/usr/bin/env bash
set -eu -o pipefail

# Prefixed names: `start-bosh` is sourced below and assigns REPO_ROOT/REPO_PARENT
# in our shell, which would otherwise clobber these.
NGINX_REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
NGINX_REPO_PARENT="$( cd "${NGINX_REPO_ROOT}/.." && pwd )"

if [[ -n "${DEBUG:-}" ]]; then
  set -x
  export DEBUG="${DEBUG}"
  export BOSH_LOG_LEVEL=debug
  export BOSH_LOG_PATH="${BOSH_LOG_PATH:-${NGINX_REPO_PARENT}/bosh-debug.log}"
fi

echo "Starting Docker and Director"
# Sourced rather than executed so the docker service can be stopped on exit;
# see https://github.com/cloudfoundry/bosh/blob/main/ci/dockerfiles/docker-cpi/README.md
source start-bosh
source /tmp/local-bosh/director/bosh-env

echo "Upload stemcell"
bosh -n upload-stemcell stemcell/stemcell.tgz

cd "${NGINX_REPO_ROOT}" # required to deploy source release

echo "Deploy nginx"
bosh -n -d test deploy \
  --var=stemcell_os="${STEMCELL_OS}" \
  manifests/test.yml

echo "Run test errand"
bosh -n -d test run-errand nginx-test
