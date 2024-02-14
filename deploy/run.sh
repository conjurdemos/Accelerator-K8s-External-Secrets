#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
source ./bin/utils

conjur_dir="$(repo_root)/deploy/kubernetes-conjur-deploy"

function cleanup {
  pushd "$conjur_dir"
    ./stop
  popd
}
trap cleanup ERR
if [[ "$DEV" != "true" ]]; then
  trap cleanup ERR EXIT
fi

pushd "$conjur_dir"
  announce "Deploying Conjur Enterprise"

  # In kubernetes-conjur-deploy, the DEV envvar indicates that the user wants
  # Conjur deployed to a local Docker Desktop K8s cluster.
  old_dev=$DEV
  # In this project, we want DEV to indicate that the user wants a live,
  # interactive env using their choice of K8s flavor, and LOCAL to indicate the
  # user wants Conjur deployed to Docker Desktop.
  export DEV=$LOCAL

  ./start
  export DEV=$old_dev
popd
