#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
LAB_URL="${1:-https://hermes-agent.nousresearch.com/}"
[[ "$LAB_URL" == https://* ]] || fail 'Provide an HTTPS source URL.'
docker compose exec -T --user hermes hermes hermes chat -q "/research-source-review $LAB_URL"
