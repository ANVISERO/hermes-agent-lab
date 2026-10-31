#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
LAB_LABEL="${1:-runtime}"
[[ "$LAB_LABEL" =~ ^[a-zA-Z0-9_-]+$ ]] || fail 'Label: letters, numbers, underscore or hyphen only.'
LAB_OUT="evidence/$(date -u +%Y%m%dT%H%M%SZ)-$LAB_LABEL"
umask 077
mkdir -p "$LAB_OUT"
capture() {
  local file="$1" result=0
  shift
  "$@" > "$LAB_OUT/$file" 2>&1 || result=$?
  printf '%s exit_code=%s\n' "$file" "$result" >> "$LAB_OUT/capture-status.txt"
}
capture time.txt date -u
capture kernel.txt uname -srmo
capture boot-id.txt cat /proc/sys/kernel/random/boot_id
capture boot-time.txt uptime -s
capture compose-ps.txt docker compose ps
capture gateway.log docker compose logs --timestamps --no-color --tail=500 hermes
capture container.txt docker inspect hermes-agent-lab --format \
  'image={{.Image}} started={{.State.StartedAt}} running={{.State.Running}} restart={{.HostConfig.RestartPolicy.Name}} privileged={{.HostConfig.Privileged}} mounts={{json .Mounts}}'
capture processes.txt docker top hermes-agent-lab -eo uid,pid,args
capture skills.txt docker compose exec -T --user hermes hermes hermes skills list
capture cron.txt docker compose exec -T --user hermes hermes hermes cron list
capture cron-runs.txt docker compose exec -T --user hermes hermes hermes cron runs --limit 20
cp compose.yaml "$LAB_OUT/compose.yaml"
python3 scripts/redact-evidence.py "$LAB_OUT" data/.env
echo "Saved to $LAB_OUT. Nonzero capture codes mean missing evidence; inspect them."
echo 'Do not publish without reviewing private chat content and identifiers.'
