#!/bin/bash

set -e
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR"

WORKLOAD_NAME=${1:-$DEFAULT_WORKLOAD_NAME}

echo "========================================Removing TAP Packages========================================"
tanzu package installed list \
  --namespace tap-install \
  -o json | jq -c '.[].name' | xargs -n1 tanzu package installed delete --yes --namespace tap-install

echo "========================================Removing TAP Repositories========================================"
tanzu package repository list \
   --namespace \
   tap-install \
   -o json | jq -c '.[].name' | xargs -n1 tanzu package repository delete --yes --namespace tap-install

echo "========================================Removing Tanzu Cluster Essentials========================================"
if [ -d "$HOME"/tanzu-cluster-essentials ]; then
  cd "$HOME"/tanzu-cluster-essentials || exit
  ./kapp delete -a secretgen-controller -n tanzu-cluster-essentials --yes || true
  ./kapp delete -a kapp-controller -n tanzu-cluster-essentials --yes || true
fi
kubectl delete ns tanzu-cluster-essentials || true
rm -rf "$HOME"/tanzu-cluster-essentials || true
rm -rf /usr/local/bin/kapp || true

echo "========================================Removing Tanzu CLI========================================"
rm -rf "$HOME"/tanzu/cli || true
rm /usr/local/bin/tanzu || true
rm -rf "$HOME"/.config/tanzu || true
rm -rf "$HOME"/.tanzu || true
rm -rf "$HOME"/tanzu || true
rm -rf "$HOME"/.cache/tanzu || true
rm -rf "$HOME"/Library/Application\ Support/tanzu-cli/* || true

echo "========================================Removing TAP Namespaces========================================"
kubectl delete ns tap-install || true
cd "$SCRIPT_DIR"
if [ -d generated ]; then rm -rd generated; fi


if [[ $1 == 'gcloud' ]]; then
   rm_gcr "$WORKLOAD_CONTAINER_REGISTRY"/build-service
   rm_gcr "$WORKLOAD_CONTAINER_REGISTRY"/supply-chain/"$WORKLOAD_NAME"-"$DEVELOPER_NAMESPACE"-bundle
   rm_gcr "$WORKLOAD_CONTAINER_REGISTRY"/supply-chain/"$WORKLOAD_NAME"-"$DEVELOPER_NAMESPACE"
fi

rm_gcr(){
 local C=0
 IMAGE="${1}"
 for digest in $(gcloud container images list-tags "${IMAGE}" \
    --limit=999999  --format='get(digest)'); do
    (
      set -x
      gcloud container images delete -q --force-delete-tags "${IMAGE}@${digest}"
    )
    (( C++ )) || true
  done
  echo "Deleted ${C} images in ${IMAGE}." >&2
}