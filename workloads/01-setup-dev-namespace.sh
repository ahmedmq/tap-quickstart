#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport


set -x
kubectl create namespace "$DEVELOPER_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

tanzu secret registry add registry-credentials \
  --server "$CONTAINER_REGISTRY_HOSTNAME" \
  --username "$CONTAINER_REGISTRY_USERNAME" \
  --password "$CONTAINER_REGISTRY_PASSWORD" \
  --namespace "$DEVELOPER_NAMESPACE"

kubectl -n "$DEVELOPER_NAMESPACE" apply -f "$SCRIPT_DIR"/setup-rbac.yaml
