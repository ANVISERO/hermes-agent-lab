#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
for file in scripts/*.sh; do bash -n "$file"; done
python3 -m unittest discover -s tests -v
# Compose parsing does not require a running daemon or pulling an image.
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  HERMES_UID=1000 HERMES_GID=1000 HERMES_IMAGE=nousresearch/hermes-agent:stable docker compose config -q
else
  echo 'SKIP: Compose parser unavailable; validate Compose on the VPS.'
fi
echo 'Local checks passed. No VPS, Telegram, LLM or autonomy result is implied.'
