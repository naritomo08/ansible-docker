# ansible-docker

Ansible を稼働するコンテナです。

SSH 公開鍵認証に必要な鍵一式は、コンテナ起動時に `/root/.ssh` へ自動作成されます。`docker-compose.yml` ではワークフォルダ内の `./ssh` を `/root/.ssh` にマウントするため、コンテナを作り直しても同じ鍵を利用できます。

`./ssh` は `.gitignore` に登録済みなので、SSH 秘密鍵は GitHub へ入りません。

## コンテナ稼働

```bash
docker-compose up -d
```

## playbook設置

playbook はホスト側の `./playbooks` に配置します。`docker-compose.yml` で `./playbooks` をコンテナ内の `/ansible/playbooks` にマウントしているため、ホストで編集した playbook をコンテナ内からそのまま実行できます。

```bash
mkdir -p playbooks
docker-compose exec ansible bash
cd /ansible/playbooks
```

## SSH鍵

コンテナ初回起動時に、以下が自動作成されます。実体はワークフォルダ内の `./ssh` に保存され、コンテナ内では `/root/.ssh` として見えます。

```bash
/root/.ssh/id_ed25519_ansible          # Ansible 接続用秘密鍵
/root/.ssh/id_ed25519_ansible.pub      # Ansible 接続用公開鍵
/root/.ssh/config                      # Ansible/ssh 用設定
```

既存ファイルがある場合は再作成しません。鍵を作り直す場合は `./ssh` を削除してから起動します。

鍵の中身を確認する場合:

```bash
docker-compose exec ansible ssh-keygen -lf /root/.ssh/id_ed25519_ansible.pub
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

## playbook稼働

```bash
docker-compose exec ansible bash
ansible-playbook ...

以下のコマンドで動作確認可能。
ターゲットノードへ公開鍵を配布し、ターゲット IP／ホストを記載した inventory ファイルを作成してください。

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

## コンテナ停止

```bash
docker-compose down
```

## 関連Qiita記事

- [個別記事から未紹介だった公開GitHubリポジトリを整理してみた](https://qiita.com/naritomo08/items/1620081b4363c3d0b400)
