#!/bin/bash

set -e

if [ -z "$1" ]; then
  tanzu package installed list --namespace tap-install
else
  tanzu package installed get "$1" --namespace tap-install
fi