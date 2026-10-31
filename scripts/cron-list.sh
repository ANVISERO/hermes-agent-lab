#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
docker compose exec -T --user hermes hermes hermes cron list
docker compose exec -T --user hermes hermes hermes cron status
