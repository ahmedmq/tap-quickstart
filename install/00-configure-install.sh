#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -f "$SCRIPT_DIR"/../.env ] && echo "Error: Environment file missing, exiting." 1>&2 && exit 1
set -o allexport; source "$SCRIPT_DIR"/../.env; set +o allexport

case "${1:-docker-desktop}" in
  docker-desktop) os=darwin;;
  gcp) os=linux;;
esac

if [[ $1 == 'gcp' ]]; then

  command -v gcloud >/dev/null && echo "gcloud not installed, exiting." 1>&2 && exit 1

  CLUSTER_ZONE="$REGION-a"
  CLUSTER_VERSION=$(gcloud container get-server-config --format="yaml(defaultClusterVersion)" \
     --region "$REGION" | awk '/defaultClusterVersion:/ {print $2}')

  # Create GKE Cluster
  gcloud container clusters create tap-cluster \
      --region="$REGION" \
      --cluster-version="$CLUSTER_VERSION" \
      --num-nodes=4 \
      --machine-type=e2-standard-4 \
      --node-locations="$CLUSTER_ZONE"

  # Create `tap-admin` service account and add required roles
  gcloud iam service-accounts create tap-admin \
      --description="TAP Admin" \
      --display-name="tap-admin"

  gcloud projects add-iam-policy-binding "$GCP_PROJECT" \
      --member="serviceAccount:tap-admin@$GCP_PROJECT.iam.gserviceaccount.com" \
      --role="roles/container.admin"


  # Create jumpbox instance to install TAP
  gcloud compute instances create tap-jump \
  --zone="$CLUSTER_ZONE" --machine-type=n2-standard-2 \
  --image-project=ubuntu-os-cloud --image-family=ubuntu-1804-lts \
  --boot-disk-type=pd-standard --boot-disk-size=100GB \
  --scopes="cloud-platform" \
  --service-account="tap-admin@$GCP_PROJECT.iam.gserviceaccount.com"

  gcloud compute scp --recursive "$SCRIPT_DIR"/../..  tap-jump

fi

if ! command -v pivnet &> /dev/null
then
   echo "Installing Pivnet CLI..."
   wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-"$1"-amd64-3.0.1
   mv pivnet-"$os"-amd64-3.0.1 /usr/local/bin/pivnet
   chmod 755 /usr/local/bin/pivnet
fi

pivnet login --api-token="$PIVNET_API_TOKEN"