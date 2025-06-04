# ───────────────────────────────────────────────
# Ubuntu + Ansible + AWS SSM (Session Manager)
# tested: 2025-06-04
# ───────────────────────────────────────────────
FROM ubuntu:22.04

# 1) 必要パッケージを APT で導入
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-pip \
        curl unzip gnupg2 ca-certificates \
        git openssh-client less groff jq \
        awscli  # ← v1.34.* が入る（1.16.12 以上なら OK） :contentReference[oaicite:0]{index=0} \
        bash bash-completion \
    && rm -rf /var/lib/apt/lists/*

# 2) Session Manager Plugin を .deb でインストール
#    (Ubuntu 公式 repo にはまだ無い)
RUN curl -Lo /tmp/session-manager-plugin.deb \
        "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" \
        && dpkg -i /tmp/session-manager-plugin.deb \
        && rm /tmp/session-manager-plugin.deb  # :contentReference[oaicite:1]{index=1}

# 3) Python venv ＋ Ansible / boto3
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install "ansible-core>=2.17,<2.18" boto3 && \
    /opt/venv/bin/ansible-galaxy collection install amazon.aws

# 4) venv を PATH に追加
ENV PATH="/opt/venv/bin:${PATH}"

# 5) 作業ディレクトリ
WORKDIR /ansible/playbooks

# 6) デバッグ用に常駐
ENTRYPOINT ["bash", "-lc", "tail -f /dev/null"]