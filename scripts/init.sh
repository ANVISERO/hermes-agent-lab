#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_docker
command -v python3 >/dev/null || fail 'Python 3 is required.'
mkdir -p data workspace evidence
chmod 700 data evidence
if [[ ! -f .env ]]; then
  # Pin before setup, so setup and gateway cannot silently use different builds.
  docker pull nousresearch/hermes-agent:stable
  LAB_IMAGE="$(docker image inspect nousresearch/hermes-agent:stable --format '{{index .RepoDigests 0}}')"
  [[ "$LAB_IMAGE" == *@sha256:* ]] || fail 'No image digest returned.'
  (umask 077; printf 'HERMES_UID=%s\nHERMES_GID=%s\nHERMES_IMAGE=%s\n' \
    "$(id -u)" "$(id -g)" "$LAB_IMAGE" > .env)
else
  echo 'Keeping existing .env and image pin.'
fi
docker compose config -q
docker compose pull hermes
echo 'Initialized. Next: bash scripts/setup.sh'
