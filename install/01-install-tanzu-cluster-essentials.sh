#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

TEMP_DIR=$(mktemp -d)

case "$K8_CLUSTER" in
  docker-desktop) PRODUCT_ID=1105820; ARCHIVE_NAME="tanzu-cluster-essentials-darwin-amd64-1.0.0.tgz" ;;
  gke) PRODUCT_ID=1105818; ARCHIVE_NAME="tanzu-cluster-essentials-linux-amd64-1.0.0.tgz";;
  *) echo "Error: Unknown value for K8_CLUSTER: $K8_CLUSTER, exiting." 1>&2 && exit 1
esac

! command -v pivnet >/dev/null && echo "pivnet not installed, exiting." 1>&2 && exit 1
! command -v jq >/dev/null && echo "jq not installed, exiting." 1>&2 && exit 1

pivnet download-product-files \
  --product-slug='tanzu-cluster-essentials' \
  --release-version='1.0.0' \
  --product-file-id=$PRODUCT_ID \
  --download-dir="$TEMP_DIR"

mkdir -p "$HOME"/tanzu-cluster-essentials
tar -xvf "$TEMP_DIR/$ARCHIVE_NAME" -C "$HOME"/tanzu-cluster-essentials

export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=$TANZUNET_USERNAME
export INSTALL_REGISTRY_PASSWORD=$TANZUNET_PASSWORD

cd "$HOME"/tanzu-cluster-essentials || exit

echo "Installing Tanzu Cluster Essentials..."
./install.sh

cp "$HOME"/tanzu-cluster-essentials/kapp /usr/local/bin/kapp