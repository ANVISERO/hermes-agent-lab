#!/usr/bin/env bash
# Run on the isolated Ubuntu VPS, not on your personal computer.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
[[ "$EUID" -ne 0 ]] || fail 'Use the Ubuntu non-root SSH user with sudo.'
[[ "$(uname -s)" == Linux ]] || fail 'This bootstrap is for an Ubuntu VPS only.'
source /etc/os-release
[[ "$ID" == ubuntu && "${VERSION_ID%%.*}" -ge 22 ]] || fail 'Ubuntu 22.04+ required.'
[[ -s "$HOME/.ssh/authorized_keys" ]] || fail 'Install and test your SSH public key first.'
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git python3 ufw
sudo install -m 0755 -d /etc/apt/keyrings
if ! command -v docker >/dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /tmp/hermes-lab-docker.asc
  sudo install -m 0644 /tmp/hermes-lab-docker.asc /etc/apt/keyrings/hermes-lab-docker.asc
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/hermes-lab-docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$(dpkg --print-architecture)" "$VERSION_CODENAME" | sudo tee /etc/apt/sources.list.d/hermes-lab-docker.list >/dev/null
  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
sudo systemctl enable --now docker
sudo usermod -aG docker "$(id -un)"
# Permit only the normal SSH port in the host firewall. Cloud firewall is separate.
[[ "$(sudo sshd -T | awk '$1 == "port" {print $2}')" == 22 ]] || fail 'Nonstandard SSH port: configure UFW manually before continuing.'
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw --force enable
echo 'Host prepared. Reconnect over SSH to activate Docker group membership.'
echo 'Next: bash scripts/harden-ssh.sh, then docker run --rm hello-world.'
