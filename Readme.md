# ansible-docker

Ansible を稼働するコンテナです。

通常の SSH 公開鍵認証と SSH ユーザー証明書認証に必要な鍵一式は、コンテナ起動時に `/root/.ssh` へ自動作成されます。`docker-compose.yml` ではワークフォルダ内の `./ssh` を `/root/.ssh` にマウントするため、コンテナを作り直しても同じ鍵と証明書を利用できます。

`./ssh` は `.gitignore` に登録済みなので、SSH 秘密鍵や証明書は GitHub へ入りません。

## コンテナ稼働

```bash
docker-compose up -d
```

## playbook設置

playbook はコンテナ内の `/ansible/playbooks` に配置します。このディレクトリも名前付き volume `ansible_playbooks` なので、ホスト側に `./playbooks` ディレクトリを作りません。

```bash
docker-compose exec ansible bash
cd /ansible/playbooks
```

## SSH鍵とSSH証明書

コンテナ初回起動時に、以下が自動作成されます。実体はワークフォルダ内の `./ssh` に保存され、コンテナ内では `/root/.ssh` として見えます。

```bash
/root/.ssh/id_ed25519_ansible          # Ansible 接続用秘密鍵
/root/.ssh/id_ed25519_ansible.pub      # Ansible 接続用公開鍵
/root/.ssh/ca_user_key                 # SSH ユーザー証明書用 CA 秘密鍵
/root/.ssh/ca_user_key.pub             # SSH ユーザー証明書用 CA 公開鍵
/root/.ssh/id_ed25519_ansible-cert.pub # 署名済み SSH ユーザー証明書
/root/.ssh/config                      # Ansible/ssh 用設定
```

既存ファイルがある場合は再作成しません。証明書を作り直したい場合は、`./ssh/id_ed25519_ansible-cert.pub` を削除してからコンテナを再起動してください。鍵そのものから作り直す場合は `./ssh` を削除してから起動します。

鍵の中身を確認する場合:

```bash
docker-compose exec ansible ssh-keygen -lf /root/.ssh/id_ed25519_ansible.pub
docker-compose exec ansible ssh-keygen -Lf /root/.ssh/id_ed25519_ansible-cert.pub
docker-compose exec ansible cat /root/.ssh/ca_user_key.pub
```

### 公開鍵認証で使う場合

ターゲットマシンの `~/.ssh/authorized_keys` に `/root/.ssh/id_ed25519_ansible.pub` の内容を登録します。

```bash
docker-compose exec ansible ssh-copy-id -i /root/.ssh/id_ed25519_ansible.pub <ユーザー名>@<ターゲットホスト/IPアドレス>
```

ターゲット側の権限は以下を基本にします。

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### SSHユーザー証明書で使う場合

ターゲットマシンで CA 公開鍵を信頼させます。`/root/.ssh/ca_user_key.pub` の内容を、ターゲットの `/etc/ssh/ansible_user_ca.pub` などへ配置してください。

```bash
sudo install -m 0644 ansible_user_ca.pub /etc/ssh/ansible_user_ca.pub
echo 'TrustedUserCAKeys /etc/ssh/ansible_user_ca.pub' | sudo tee /etc/ssh/sshd_config.d/ansible-user-ca.conf
sudo systemctl reload sshd
```

証明書の principal は既定で `ansible,root` です。接続ユーザー名と合わせたい場合は、起動前に `ANSIBLE_SSH_CERT_PRINCIPALS` を compose の environment に追加します。

```bash
environment:
  - ANSIBLE_SSH_CERT_PRINCIPALS=naritomo
```

## playbook稼働

```bash
docker-compose exec ansible bash
ansible-playbook ...

以下のコマンドで動作確認可能。
ターゲットノードへ公開鍵または CA 公開鍵を配布し、ターゲット IP／ホストを記載した inventory ファイルを作成してください。

ansible all -i hosts.ini -m ping
```

inventory(hosts.ini)について、以下の設定を基本として作成すること。

```bash
[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=/root/.ssh/id_ed25519_ansible
ansible_python_interpreter=/usr/bin/python3

[ansible_hosts]
<ターゲットのホスト名・IPアドレス>
```

SSH 証明書は `/root/.ssh/config` で `CertificateFile /root/.ssh/id_ed25519_ansible-cert.pub` として設定済みです。

## コンテナ停止

```bash
docker-compose down
```

## 関連Qiita記事

- [個別記事から未紹介だった公開GitHubリポジトリを整理してみた](https://qiita.com/naritomo08/items/1620081b4363c3d0b400)
