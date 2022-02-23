#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

mkdir -p generated
case "${1:-docker-desktop}" in
  docker-desktop) valuesFile="$SCRIPT_DIR"/tap-values.yaml.docker-desktop.sample;;
  gcp) valuesFile="$SCRIPT_DIR"/tap-values.yaml.gcp.sample; GCP_JSON_KEY_CONTENTS="$(cat GCP_CREDENTIALS_JSON_FILE)"; export GCP_JSON_KEY_CONTENTS;;
esac

envsubst < "$valuesFile" > generated/tap-values.yaml

echo "Installing TAP..."
tanzu package install tap \
   -p tap.tanzu.vmware.com -v 1.0.1 \
   --values-file generated/tap-values.yaml \
   -n tap-install