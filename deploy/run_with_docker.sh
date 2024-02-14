#!/usr/bin/env bash
set -eo pipefail
cd "$(git rev-parse --show-toplevel)"
source ./bin/utils

run_docker_cmd "./run.sh"
