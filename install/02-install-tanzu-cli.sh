#!/bin/bash

set -e

TEMP_DIR=$(mktemp -d)

case "${1:-docker-desktop}" in
  docker-desktop) PRODUCT_ID=1156161; ARCHIVE_NAME="tanzu-framework-darwin-amd64.tar";;
  gcp) PRODUCT_ID=1156163; ARCHIVE_NAME="tanzu-framework-linux-amd64.tar";;
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
install cli/core/v0.11.1/tanzu-core-"${1:-darwin}"_amd64 /usr/local/bin/tanzu
tanzu version

echo "Installing Tanzu CLI Plugin..."
tanzu plugin install --local cli all
tanzu plugin list