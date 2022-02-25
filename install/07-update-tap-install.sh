#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

mkdir -p generated
case "$K8_CLUSTER" in
  docker-desktop) valuesFile="$SCRIPT_DIR"/tap-values.yaml.docker-desktop.sample;;
  gke) valuesFile="$SCRIPT_DIR"/tap-values.yaml.gke.sample;;
  *) echo "Error: Unknown value for K8_CLUSTER: $K8_CLUSTER, exiting." 1>&2 && exit 1
esac

envsubst < "$valuesFile" > generated/tap-values.yaml

if [ "$K8_CLUSTER" == 'gke' ]; then
  # To replace the text GCP_CREDENTIALS_JSON_FILE in the template file with the actual credentials JSON string
  awk 'NR==FNR { a[n++]=$0; next } /<<GCP_CREDENTIALS_JSON_FILE>>/ { for (i=0;i<n;++i) print "    "a[i]; next } 1' "$CONTAINER_REGISTRY_PASSWORD" generated/tap-values.yaml > generated/temp.yaml
  mv generated/temp.yaml generated/tap-values.yaml
fi

echo "Updating TAP..."
tanzu package installed update tap \
   -p tap.tanzu.vmware.com -v 1.0.1 \
   --values-file generated/tap-values.yaml \
   -n tap-install