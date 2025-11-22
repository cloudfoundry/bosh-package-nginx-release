#!/bin/bash

set -eux

dir=$(dirname "${0}")

fly -t "${CONCOURSE_TARGET:-bosh}" set-pipeline \
	-p nginx-release \
	-c "${dir}/pipeline.yml"
