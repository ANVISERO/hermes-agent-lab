#!/usr/bin/env bash
# Use an explicit non-root user for CLI operations inside the running container.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
docker compose exec --user hermes hermes hermes "$@"
