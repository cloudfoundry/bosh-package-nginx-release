#!/bin/bash

set -eux

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

cat >> config/private.yml <<EOF
---
blobstore:
  provider: s3
  options:
    access_key_id: "$BLOBSTORE_ACCESS_KEY_ID"
    secret_access_key: "$BLOBSTORE_SECRET_ACCESS_KEY"
    assume_role_arn: "$BLOBSTORE_ASSUME_ROLE_ARN"
EOF

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
