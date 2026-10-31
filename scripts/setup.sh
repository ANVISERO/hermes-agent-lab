#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_config
[[ "$(docker inspect hermes-agent-lab --format '{{.State.Running}}' 2>/dev/null || true)" != true ]] \
  || fail 'Stop the gateway before interactive setup: bash scripts/stop.sh.'
mkdir -p data/memories data/skills/research-source-review workspace evidence
chmod 700 data evidence
for name in USER.md MEMORY.md; do
  [[ -e "data/memories/$name" ]] || cp "templates/memories/$name" "data/memories/$name"
done
[[ -e data/skills/research-source-review/SKILL.md ]] \
  || cp skills/research-source-review/SKILL.md data/skills/research-source-review/SKILL.md
echo 'Configure the provider and a free model with >=64K context and tool support.'
echo 'Set a provider spending limit BEFORE enabling scheduled jobs.'
docker compose run --rm --no-deps hermes setup
echo 'Configure Telegram with ONLY your numeric user ID. Never allow all users.'
docker compose run --rm --no-deps hermes gateway setup
docker compose run --rm --no-deps hermes config set terminal.backend local
docker compose run --rm --no-deps hermes config set terminal.cwd /workspace
check_access
chmod 600 data/.env
echo 'Setup complete. Review data/config.yaml, then: bash scripts/start.sh'
