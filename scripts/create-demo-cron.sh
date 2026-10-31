#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
check_access
LAB_CHAT="${1:-}"
[[ "$LAB_CHAT" =~ ^[1-9][0-9]*$ ]] || fail 'Usage: bash scripts/create-demo-cron.sh YOUR_PRIVATE_CHAT_ID'
# For this lab allow delivery only to the owner's private chat.
python3 scripts/check_access.py data/.env --chat-id "$LAB_CHAT"
LAB_PROMPT="Use the terminal to run date -u, uptime and df -h /workspace. Append the actual UTC execution time and command results to /workspace/autonomy-check.log. Return a concise report headed P1 autonomous check. If a tool fails, report the actual failure. Do not invent output."
docker compose exec -T --user hermes hermes hermes cron create 'in 10m' "$LAB_PROMPT" \
  --name 'P1 closed-client check' --deliver "telegram:$LAB_CHAT"
docker compose exec -T --user hermes hermes hermes cron list
echo 'One-shot job scheduled. Save its ID and due time; close Telegram and SSH.'
