#!/bin/bash

set -e # -x

echo "-----> `date`: Upload stemcell"
bosh -n upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=3468.15" \
  --sha1 8b5b4d842d829d3c9e0582b2f53de3b3bb576ff5 \
  --name bosh-warden-boshlite-ubuntu-trusty-go_agent \
  --version 3468.15

echo "-----> `date`: Delete previous deployment"
bosh -n -d test delete-deployment --force

echo "-----> `date`: Deploy"
( set -e; cd ./..; bosh -n -d test deploy ./manifests/test.yml )

echo "-----> `date`: Run test errand"
bosh -n -d test run-errand nginx-1.12-test

echo "-----> `date`: Delete deployments"
bosh -n -d test delete-deployment

echo "-----> `date`: Done"
