#!/bin/bash

set -eux

dir=$(dirname $0)

fly -t bosh-ecosystem set-pipeline \
	-p nginx-release \
	-c $dir/pipeline.yml
