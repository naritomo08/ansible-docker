FROM ubuntu:22.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-pip \
        ca-certificates \
        git openssh-client sshpass less jq \
        bash bash-completion vim-tiny \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install "ansible-core>=2.17,<2.18"

ENV PATH="/opt/venv/bin:${PATH}"
ENV ANSIBLE_CONFIG="/etc/ansible/ansible.cfg"

COPY ansible/ansible.cfg /etc/ansible/ansible.cfg
COPY ansible/hosts.ini /etc/ansible/hosts.ini
COPY docker/entrypoint.sh /usr/local/bin/ansible-container-entrypoint

RUN chmod 755 /usr/local/bin/ansible-container-entrypoint && \
    mkdir -p /ansible/playbooks /root/.ssh && \
    chmod 700 /root/.ssh

WORKDIR /ansible/playbooks

ENTRYPOINT ["/usr/local/bin/ansible-container-entrypoint"]
CMD ["tail", "-f", "/dev/null"]
