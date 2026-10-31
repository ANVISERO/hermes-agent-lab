#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_config
docker compose logs --timestamps --tail=200 -f hermes
