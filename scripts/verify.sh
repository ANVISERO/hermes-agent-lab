#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
check_access
docker compose config --format json | python3 -c '
import json, sys
s = json.load(sys.stdin)["services"]["hermes"]
assert s["restart"] == "unless-stopped", "wrong restart policy"
assert not s.get("ports"), "published ports are unexpected"
assert not s.get("privileged"), "privileged container is forbidden"
assert not any("docker.sock" in str(v) for v in s["volumes"]), "Docker socket mount"
assert {v["target"] for v in s["volumes"]} == {"/opt/data", "/workspace"}, "unexpected mounts"
assert "@sha256:" in s["image"], "image is not pinned"
print("PASS: Compose policy")
'
[[ "$(docker inspect hermes-agent-lab --format '{{.HostConfig.RestartPolicy.Name}}')" == unless-stopped ]] \
  || fail 'Running container has wrong restart policy; recreate it.'
[[ "$(docker inspect hermes-agent-lab --format '{{.HostConfig.Privileged}}')" == false ]] \
  || fail 'Running container is privileged.'
for path in data/memories/USER.md data/memories/MEMORY.md data/skills/research-source-review/SKILL.md; do
  [[ -s "$path" ]] || fail "Missing or empty: $path"
done
docker top hermes-agent-lab -eo uid,pid,args
docker compose exec -T --user hermes hermes hermes skills list
docker compose exec -T --user hermes hermes hermes cron status
echo 'Preflight passed. Manually verify a non-root gateway process, active Telegram,'
echo 'nonzero skills, real tool calls, provider spending limit and unauthorized-user denial.'
