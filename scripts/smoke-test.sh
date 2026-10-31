#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
PROMPT="Run a P1 smoke test. Use terminal to execute date -u. Use a file tool to write P1-FILE-OK into /workspace/p1-smoke.txt, then read it back. Use web_extract to read https://example.com and report its actual title. Use web_search to find two official sources about reproducible computational research. Report each actual tool call and any failure. Never substitute an assertion for a missing tool call."
docker compose exec -T --user hermes hermes hermes chat -q "$PROMPT"
echo 'Review the actual tool trace; this script alone does not certify success.'
