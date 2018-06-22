#!/bin/bash

set -eux

dir=$(dirname $0)

fly -t production login -n bosh-packages -u bosh-packages

fly -t production set-pipeline \
	-p nginx-release \
	-c $dir/pipeline.yml \
	-l <(lpass show --note "bosh-packages-concourse-vars-nginx-release")
