#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
[[ "$EUID" -ne 0 ]] || fail 'Run as your tested non-root SSH user.'
[[ "$(uname -s)" == Linux ]] || fail 'Ubuntu VPS only.'
[[ -s "$HOME/.ssh/authorized_keys" ]] || fail 'A tested authorized_keys file is required.'
LAB_SSH_FILE=/etc/ssh/sshd_config.d/00-hermes-agent-lab.conf
[[ ! -e "$LAB_SSH_FILE" ]] || fail "Already exists: $LAB_SSH_FILE. Inspect effective SSH settings manually."
LAB_SSH_TEMP="$(mktemp)"
trap 'rm -f "$LAB_SSH_TEMP"' EXIT
cat > "$LAB_SSH_TEMP" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF
sudo install -m 0644 "$LAB_SSH_TEMP" "$LAB_SSH_FILE"
if ! sudo sshd -t; then
  sudo rm "$LAB_SSH_FILE"
  fail 'Invalid SSH configuration; removed the new drop-in and did not reload SSH.'
fi
LAB_EFFECTIVE="$(sudo sshd -T)"
for required in 'passwordauthentication no' 'kbdinteractiveauthentication no' 'permitrootlogin no' 'pubkeyauthentication yes'; do
  if ! printf '%s\n' "$LAB_EFFECTIVE" | grep -qx "$required"; then
    sudo rm "$LAB_SSH_FILE"
    fail 'An earlier SSH setting overrides this drop-in. No reload performed; inspect manually.'
  fi
done
sudo systemctl reload ssh
echo 'Keep this session open. Verify a SECOND SSH key login before closing it.'
