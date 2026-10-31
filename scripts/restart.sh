#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
check_access
docker compose restart hermes
