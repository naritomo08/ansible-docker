# ───────────────────────────────────────────────────────
# Dockerfile (Alpine 3.20) for Ansible + boto3 + AWS SSM
# ───────────────────────────────────────────────────────
FROM alpine:3.20

# 1) 基本パッケージを apk でインストール
RUN apk update && \
    apk add --no-cache \
        python3        \
        py3-pip        \
        openssh-client \
        git            \
        curl           \
        unzip          \
        groff          \
        less

# 2) Python 仮想環境を /opt/venv に作成し、ansible-core と boto3 を入れる
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir "ansible-core>=2.16,<2.17" boto3

# 3) 仮想環境の bin を PATH に追加して ansible コマンドを使えるようにする
ENV PATH="/opt/venv/bin:${PATH}"

# 4) community.aws コレクションをインストール（aws_ssm プラグインが含まれる）
RUN ansible-galaxy collection install amazon.aws

# 5) Session Manager プラグインをダウンロードしてインストール
#RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.zip" \
    #-o "/tmp/session-manager-plugin.zip" && \
    #unzip /tmp/session-manager-plugin.zip -d /tmp/session-manager-plugin && \
    #mv /tmp/session-manager-plugin/session-manager-plugin /usr/local/bin/session-manager-plugin && \
    #chmod +x /usr/local/bin/session-manager-plugin && \
    #rm -rf /tmp/session-manager-plugin /tmp/session-manager-plugin.zip

# 6) 動作確認（オプション）
#RUN session-manager-plugin --version && \
    #ansible --version && \
    #python3 -c "import boto3; print('boto3:', boto3.__version__)"

# 7) 作業ディレクトリを /ansible/playbooks に設定
WORKDIR /ansible/playbooks

# 8) コンテナ起動時に常駐プロセスを走らせる
ENTRYPOINT ["/bin/sh", "-c", "tail -f /dev/null"]
