#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_running
LAB_MARKER="P1-FILE-OK $(python3 -c 'import uuid; print(uuid.uuid4().hex)')"
printf 'Expected file marker for this run: %s\n' "$LAB_MARKER"
PROMPT="Run a P1 smoke test. Use terminal to execute date -u. Use a file-writing tool (not a shell command) to write the exact text '$LAB_MARKER' into /workspace/p1-smoke.txt, then read that same path using a file-reading tool. If a write is denied, report the error and do not move the file to another directory. Use web_extract to read https://example.com and report its actual title. Use web_search to find two official sources about reproducible computational research. Report each actual tool call and any failure. Never substitute an assertion for a missing tool call."
docker compose exec -T --user hermes hermes hermes chat -q "$PROMPT"
# An alternative path or a stale file from an earlier run must not pass.
docker compose exec -T --user hermes hermes python3 -c '
import sys
from pathlib import Path
path = Path("/workspace/p1-smoke.txt")
if not path.is_file():
    sys.exit("FAIL: /workspace/p1-smoke.txt was not created; another path does not satisfy this test")
if path.read_text().strip() != sys.argv[1]:
    sys.exit("FAIL: /workspace/p1-smoke.txt does not contain the expected current-run marker")
print("PASS: /workspace/p1-smoke.txt contains the current run marker")
' "$LAB_MARKER"
echo 'File postcondition passed. Review the actual tool trace for terminal, file tools, web_search and web_extract.'
