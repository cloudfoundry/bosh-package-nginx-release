#!/usr/bin/env bash

set -eu

task_dir=$PWD
repo_output=$task_dir/output_repo

git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"

git clone input_repo "$repo_output"

cd "$repo_output"

echo "$PRIVATE_YML" > config/private.yml

for package in $(echo "$PACKAGES" | jq -r '.[]'); do
  bosh vendor-package "${package}" "$task_dir/nginx-release"
done

if [ -z "$(git status --porcelain)" ]; then
  exit
fi

git add -A

package_list=$(echo "$PACKAGES" | jq -r 'join(", ")')
first_package=$(echo "$PACKAGES" | jq -r '.[0]')
first_version=$(cat "$task_dir/nginx-release/packages/$first_package/version")
git commit -m "Update $package_list packages to $first_version from nginx-release"
