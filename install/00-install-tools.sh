#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

case "$K8_CLUSTER" in
  docker-desktop) os="darwin";;
  gke) os="linux";;
  *) echo "Error: Unknown value for K8_CLUSTER: $K8_CLUSTER, exiting." 1>&2 && exit 1
esac

TEMP_DIR=$(mktemp -d)

if [ "$os" == "linux" ]; then
  echo "Installing basic tools..."
  sudo apt-get update -y
  sudo apt-get install -y \
     curl \
     jq
elif [ "$os" == "darwin" ]; then
     echo "Installing basic tools..."
    ! command -v jq &> /dev/null && brew install curl
    ! command -v curl &> /dev/null && brew install jq
fi

if ! command -v pivnet &> /dev/null
then
   echo "Installing Pivnet CLI..."
   curl -Lo "$TEMP_DIR"/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-$os-amd64-3.0.1
   sudo install -o root -g root -m 0755 "$TEMP_DIR"/pivnet /usr/local/bin/pivnet
fi

if ! command -v kubectl &> /dev/null
then
  echo "Installing kubectl..."
  curl -Lo "$TEMP_DIR"/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$os/amd64/kubectl"
  sudo install -o root -g root -m 0755 "$TEMP_DIR"/kubectl /usr/local/bin/kubectl
  gcloud container clusters get-credentials tap-cluster --region="$GCP_REGION"
fi

pivnet login --api-token="$PIVNET_API_TOKEN"

