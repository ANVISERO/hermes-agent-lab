#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_config
check_access
docker compose up -d hermes
docker compose ps
echo 'Check the gateway logs and Telegram before claiming a successful deployment.'
