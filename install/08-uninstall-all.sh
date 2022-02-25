#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR" || true

[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

WORKLOAD_NAME=${1:-$DEFAULT_WORKLOAD_NAME}

TAP_INSTALL_NS_STATUS=$(kubectl get ns tap-install --ignore-not-found=true -ojson | jq .status.phase -r)
TAP_CLUSTER_ESSENTIALS_NS_STATUS=$(kubectl get ns tanzu-cluster-essentials --ignore-not-found=true -ojson | jq .status.phase -r)


echo "========================================Removing TAP Packages========================================"
[ "$TAP_INSTALL_NS_STATUS" == "Active" ] && tanzu package installed list \
  --namespace tap-install \
  -o json | jq -c '.[].name' | xargs -n1 tanzu package installed delete --yes --namespace tap-install

echo "========================================Removing TAP Repositories========================================"
[ "$TAP_INSTALL_NS_STATUS" == "Active" ] && tanzu package repository list \
   --namespace \
   tap-install \
   -o json | jq -c '.[].name' | xargs -n1 tanzu package repository delete --yes --namespace tap-install

echo "========================================Removing Tanzu Cluster Essentials========================================"
if [ -d "$HOME"/tanzu-cluster-essentials ]; then
  cd "$HOME"/tanzu-cluster-essentials || exit
  [ "$TAP_CLUSTER_ESSENTIALS_NS_STATUS" == "Active" ] && { ./kapp delete -a secretgen-controller -n tanzu-cluster-essentials --yes || true; }
  [ "$TAP_CLUSTER_ESSENTIALS_NS_STATUS" == "Active" ] && { ./kapp delete -a kapp-controller -n tanzu-cluster-essentials --yes || true; }
fi
[ "$TAP_CLUSTER_ESSENTIALS_NS_STATUS" == "Active" ] && { kubectl delete ns tanzu-cluster-essentials || true; }
rm -rf "$HOME"/tanzu-cluster-essentials || true
rm -rf /usr/local/bin/kapp || true

echo "========================================Removing Tanzu CLI========================================"
rm -rf "$HOME"/tanzu/cli || true
rm -rf /usr/local/bin/tanzu || true
rm -rf "$HOME"/.config/tanzu || true
rm -rf "$HOME"/.tanzu || true
rm -rf "$HOME"/tanzu || true
rm -rf "$HOME"/.cache/tanzu || true
rm -rf "$HOME"/Library/Application\ Support/tanzu-cli/* || true

echo "========================================Removing TAP Namespaces========================================"
[ "$TAP_INSTALL_NS_STATUS" == "Active" ] && { kubectl delete ns tap-install || true; }
cd "$SCRIPT_DIR" || true
if [ -d generated ]; then rm -rd generated; fi


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

if [ "$K8_CLUSTER" == 'gke' ]; then

   echo "Deleting GKE Cluster..."
   gcloud container clusters delete tap-cluster -q --region="$GCP_REGION"

   echo "Deleting container images..."
   rm_gcr "$CONTAINER_REGISTRY_HOSTNAME"/"$CONTAINER_REPOSITORY"/build-service
   rm_gcr "$CONTAINER_REGISTRY_HOSTNAME"/"$CONTAINER_REPOSITORY"/supply-chain/"$WORKLOAD_NAME"-"$DEVELOPER_NAMESPACE"-bundle
   rm_gcr "$CONTAINER_REGISTRY_HOSTNAME"/"$CONTAINER_REPOSITORY"/supply-chain/"$WORKLOAD_NAME"-"$DEVELOPER_NAMESPACE"
fi

