#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

case "$K8_CLUSTER" in
  docker-desktop) CONTAINER_REG_PASS=$CONTAINER_REGISTRY_PASSWORD;;
  gke) CONTAINER_REG_PASS=$(cat "$CONTAINER_REGISTRY_PASSWORD");;
  *) echo "Error: Unknown value for K8_CLUSTER: $K8_CLUSTER, exiting." 1>&2 && exit 1
esac

set -x
kubectl create namespace "$DEVELOPER_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

tanzu secret registry add registry-credentials \
  --server "$CONTAINER_REGISTRY_HOSTNAME" \
  --username "$CONTAINER_REGISTRY_USERNAME" \
  --password "$CONTAINER_REG_PASS" \
  --namespace "$DEVELOPER_NAMESPACE"

kubectl -n "$DEVELOPER_NAMESPACE" apply -f "$SCRIPT_DIR"/setup-rbac.yaml
set +x