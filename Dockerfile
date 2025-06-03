# Dockerfile
FROM alpine:3.20

# ベースツール + ansible-core + コレクションを導入
RUN apk update && \
    apk add --no-cache \
        python3 \
        openssh-client \
        git \
        ansible

WORKDIR /ansible/playbooks
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["tail -f /dev/null"]