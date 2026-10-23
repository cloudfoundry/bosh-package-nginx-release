#!/bin/bash

set -euxo pipefail

ROOT_DIR=${PWD}

shopt -s nullglob
archives=(nginx-src/nginx-*.tar.gz)
shopt -u nullglob
if [[ ${#archives[@]} -ne 1 ]]; then
    echo "Expected exactly one nginx source archive" >&2
    exit 1
fi
latest_blob_path="${ROOT_DIR}/${archives[0]}"
latest_blob_name=$(basename "${latest_blob_path}")
latest_version=$(cat nginx-src/version)
if [[ ! ${latest_version} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || ${latest_blob_name} != "nginx-${latest_version}.tar.gz" ]]; then
    echo "Archive name does not match nginx version" >&2
    exit 1
fi

# Verify against the committed publisher keys before any blobstore operations.
verification_home=$(mktemp -d)
trap 'rm -rf "${verification_home}"' EXIT
chmod 700 "${verification_home}"
curl --fail --silent --show-error --location \
    "https://nginx.org/download/${latest_blob_name}.asc" \
    --output "${verification_home}/source.asc"
GNUPGHOME="${verification_home}" gpgv --keyring "${ROOT_DIR}/nginx-release/keys/nginx.gpg" \
    "${verification_home}/source.asc" "${latest_blob_path}"

cd nginx-release

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

bosh sync-blobs

previous_blob=$(ls blobs/nginx-1.*.tar.gz | cut -c 7-)

if [ "${previous_blob}" == "${latest_blob_name}" ]; then
    exit
fi

bosh remove-blob "${previous_blob}"
bosh add-blob "${latest_blob_path}" "${latest_blob_name}"
bosh upload-blobs

echo "${latest_version}" > packages/nginx/version

if [ -z "$(git status --porcelain)" ]; then
    exit
fi

git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git commit -am "Bump to nginx ${latest_version}"
