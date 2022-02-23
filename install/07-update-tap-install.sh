#!/bin/bash

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR"

[ ! -f ../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source ../.env; set +o allexport

mkdir -p generated
case "${1:-docker-desktop}" in
  docker-desktop) valuesFile="$SCRIPT_DIR"/local/tap-values-local.yaml.tpl;;
  gcp) valuesFile="$SCRIPT_DIR"/gcloud/tap-values-gcloud.yaml.tpl;;
esac

envsubst < "$valuesFile" > generated/tap-values.yaml

echo "Installing TAP..."
tanzu package installed update tap \
   -p tap.tanzu.vmware.com -v 1.0.1 \
   --values-file generated/tap-values.yaml \
   -n tap-install