#!/usr/bin/env bash
# Shared helpers; source this file rather than executing it.
set -euo pipefail
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$LAB_ROOT"
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
require_docker() {
  [[ "$EUID" -ne 0 ]] || fail 'Run as a non-root VPS user.'
  command -v docker >/dev/null || fail 'Install Docker with scripts/bootstrap-host.sh.'
  docker info >/dev/null 2>&1 || fail 'Docker unavailable. Start Docker or reconnect after group change.'
  docker compose version >/dev/null || fail 'Docker Compose plugin is required.'
}
require_config() {
  require_docker
  [[ -f .env ]] || fail 'Run bash scripts/init.sh first.'
  docker compose config -q
}
require_running() {
  require_config
  [[ "$(docker inspect hermes-agent-lab --format '{{.State.Running}}' 2>/dev/null)" == true ]] \
    || fail 'Gateway container is not running. Use scripts/start.sh.'
}
check_access() {
  command -v python3 >/dev/null || fail 'Python 3 is required.'
  python3 scripts/check_access.py data/.env
}
