#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
docker compose ps
docker inspect hermes-agent-lab --format \
  'running={{.State.Running}} started={{.State.StartedAt}} restart={{.HostConfig.RestartPolicy.Name}} image={{.Image}}'
docker top hermes-agent-lab -eo uid,pid,args
docker compose exec -T --user hermes hermes hermes cron status
