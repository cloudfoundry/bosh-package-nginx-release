#!/bin/bash

set -euxo pipefail

ROOT_DIR=${PWD}

latest_blob_path="${ROOT_DIR}/$(ls nginx-src/nginx-*.tar.gz)"
latest_blob_name=$(basename "${latest_blob_path}")
latest_version=$(cat nginx-src/version)

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
