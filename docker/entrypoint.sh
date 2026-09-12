#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="${ANSIBLE_SSH_DIR:-/root/.ssh}"
KEY_PATH="${ANSIBLE_SSH_KEY_PATH:-${SSH_DIR}/id_ed25519_ansible}"

mkdir -p "${SSH_DIR}"
# Allow host users to list keys.
chmod 755 "${SSH_DIR}"

if [ ! -f "${KEY_PATH}" ]; then
  ssh-keygen -q -t ed25519 -N "" -C "ansible-docker" -f "${KEY_PATH}"
fi

if [ ! -f "${KEY_PATH}.pub" ]; then
  ssh-keygen -y -f "${KEY_PATH}" > "${KEY_PATH}.pub"
fi

cat > "${SSH_DIR}/config" <<EOF
Host *
    IdentityFile ${KEY_PATH}
    CertificateFile none
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 4
EOF

chmod 600 "${KEY_PATH}"
chmod 644 "${SSH_DIR}/config" "${KEY_PATH}.pub"

exec "$@"
