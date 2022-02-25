#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

WORKLOAD_NAME=${1:-$DEFAULT_WORKLOAD_NAME}

set -x
tanzu apps workload tail "$WORKLOAD_NAME"\
  --since 10m \
  --timestamp \
  --namespace "$DEVELOPER_NAMESPACE"
