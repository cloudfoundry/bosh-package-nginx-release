#!/bin/bash

set -euxo pipefail

cd nginx-release

echo "Build new release"

git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

bosh upload-blobs

if [[ -n $(git status --porcelain) ]]; then
  git add -A
  git status
  git commit -m "Adding blobs via concourse"
fi

bosh create-release --final

if [[ -n $(git status --porcelain) ]]; then
  git add -A
  git status
  git commit -m "Final release via concourse"
fi
