#!/bin/bash

set -e # -x

echo "-----> `date`: Upload stemcell"
bosh -n upload-stemcell --sha1 eaed304802aee6050b1f5c680fe8c3fb8e9b5fed \
  https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-bionic-go_agent?v=1.36

echo "-----> `date`: Delete previous deployment"
bosh -n -d test delete-deployment --force

echo "-----> `date`: Deploy"
( set -e; cd ./..; bosh -n -d test deploy ./manifests/test.yml )

echo "-----> `date`: Run test errand"
bosh -n -d test run-errand nginx-test

echo "-----> `date`: Delete deployments"
bosh -n -d test delete-deployment

echo "-----> `date`: Done"
