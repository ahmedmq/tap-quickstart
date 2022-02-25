#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

! command -v gcloud >/dev/null && echo "gcloud not installed, exiting." 1>&2 && exit 1

CLUSTER_ZONE="$GCP_REGION-a"
CLUSTER_VERSION=$(gcloud container get-server-config --format="yaml(defaultClusterVersion)" \
   --region "$GCP_REGION" | awk '/defaultClusterVersion:/ {print $2}')
GCP_PROJECT="$(gcloud config get-value core/project -q)"

# Create GKE Cluster
gcloud container clusters create tap-cluster \
    --region="$GCP_REGION" \
    --cluster-version="$CLUSTER_VERSION" \
    --num-nodes=4 \
    --machine-type=e2-standard-4 \
    --node-locations="$CLUSTER_ZONE"

# Create jump-box instance to install TAP
gcloud compute instances create tap-jump \
--zone="$CLUSTER_ZONE" --machine-type=n2-standard-2 \
--image-project=ubuntu-os-cloud --image-family=ubuntu-1804-lts \
--boot-disk-type=pd-standard --boot-disk-size=100GB \
--scopes="cloud-platform" \
--service-account="$GCP_SERVICE_ACCOUNT_NAME@$GCP_PROJECT.iam.gserviceaccount.com"

gcloud compute scp --zone="$CLUSTER_ZONE" --recurse ../tap-quickstart tap-jump:~

echo "SSH access using: gcloud compute ssh tap-jump --zone=$CLUSTER_ZONE"



