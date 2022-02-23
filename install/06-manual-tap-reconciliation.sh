#!/bin/bash

set -e

test -z "$1" && echo "Error: package name required" 1>&2 && exit 1

TAP_NS=tap-install
kubectl -n $TAP_NS patch packageinstalls.packaging.carvel.dev "$1" \
  --type='json' -p '[{"op": "add", "path": "/spec/paused", "value":true}]}}'

kubectl -n $TAP_NS patch packageinstalls.packaging.carvel.dev "$1" \
--type='json' -p '[{"op": "add", "path": "/spec/paused", "value":false}]}}'