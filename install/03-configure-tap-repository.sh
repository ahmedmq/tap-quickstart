#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

kubectl create ns tap-install || true

tanzu secret registry add tap-registry \
  --username "$TANZUNET_USERNAME" --password "$TANZUNET_PASSWORD" \
  --server "$TANZUNET_REGISTRY" \
  --export-to-all-namespaces \
  --yes \
  --namespace tap-install

tanzu package repository add tanzu-tap-repository \
  --url "$TANZUNET_REGISTRY/tanzu-application-platform/tap-packages:1.0.1" \
  --namespace tap-install

tanzu package repository get tanzu-tap-repository --namespace tap-install
