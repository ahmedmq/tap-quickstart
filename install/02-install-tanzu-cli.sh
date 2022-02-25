#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

TEMP_DIR=$(mktemp -d)

case "$K8_CLUSTER" in
  docker-desktop) os="darwin"; PRODUCT_ID=1156161; ARCHIVE_NAME="tanzu-framework-darwin-amd64.tar";;
  gke) os="linux"; PRODUCT_ID=1156163; ARCHIVE_NAME="tanzu-framework-linux-amd64.tar";;
  *) echo "Error: Unknown value for K8_CLUSTER: $K8_CLUSTER, exiting." 1>&2 && exit 1
esac

pivnet download-product-files \
  --product-slug='tanzu-application-platform' \
  --release-version='1.0.1' \
  --product-file-id=$PRODUCT_ID \
  --download-dir="$TEMP_DIR"

mkdir -p "$HOME"/tanzu
tar -xvf "$TEMP_DIR/$ARCHIVE_NAME" -C "$HOME"/tanzu

export TANZU_CLI_NO_INIT=true

cd "$HOME"/tanzu || exit

echo "Installing Tanzu CLI..."
install cli/core/v0.11.1/tanzu-core-"$os"_amd64 /usr/local/bin/tanzu
tanzu version

echo "Installing Tanzu CLI Plugin..."
tanzu plugin install --local cli all
tanzu plugin list