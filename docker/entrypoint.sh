#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="${ANSIBLE_SSH_DIR:-/root/.ssh}"
KEY_PATH="${ANSIBLE_SSH_KEY_PATH:-${SSH_DIR}/id_ed25519_ansible}"
CA_KEY_PATH="${ANSIBLE_SSH_CA_KEY_PATH:-${SSH_DIR}/ca_user_key}"
CERT_ID="${ANSIBLE_SSH_CERT_ID:-ansible-docker}"
CERT_PRINCIPALS="${ANSIBLE_SSH_CERT_PRINCIPALS:-ansible,root}"
CERT_VALIDITY="${ANSIBLE_SSH_CERT_VALIDITY:-+52w}"

mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"

if [ ! -f "${KEY_PATH}" ]; then
  ssh-keygen -q -t ed25519 -N "" -C "ansible-docker" -f "${KEY_PATH}"
fi

if [ ! -f "${CA_KEY_PATH}" ]; then
  ssh-keygen -q -t ed25519 -N "" -C "ansible-docker-user-ca" -f "${CA_KEY_PATH}"
fi

if [ ! -f "${KEY_PATH}-cert.pub" ] || ! ssh-keygen -Lf "${KEY_PATH}-cert.pub" >/dev/null 2>&1; then
  rm -f "${KEY_PATH}-cert.pub"
  ssh-keygen -q \
    -s "${CA_KEY_PATH}" \
    -I "${CERT_ID}" \
    -n "${CERT_PRINCIPALS}" \
    -V "${CERT_VALIDITY}" \
    "${KEY_PATH}.pub"
fi

cat > "${SSH_DIR}/config" <<EOF
Host *
    IdentityFile ${KEY_PATH}
    CertificateFile ${KEY_PATH}-cert.pub
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 4
EOF

chmod 600 "${KEY_PATH}" "${CA_KEY_PATH}" "${SSH_DIR}/config"
chmod 644 "${KEY_PATH}.pub" "${KEY_PATH}-cert.pub" "${CA_KEY_PATH}.pub"

exec "$@"
