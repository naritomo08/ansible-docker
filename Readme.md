# ansible-docker

Ansible を稼働するコンテナです。

SSH 公開鍵認証に必要な鍵一式は、コンテナ起動時に `/root/.ssh` へ自動作成されます。`docker-compose.yml` ではワークフォルダ内の `./ssh` を `/root/.ssh` にマウントするため、コンテナを作り直しても同じ鍵を利用できます。

`./ssh` は `.gitignore` に登録済みなので、SSH 秘密鍵は GitHub へ入りません。

`./ssh` の権限は `755` とし、どのユーザーでもファイル一覧を表示できます。公開鍵と SSH 設定（`config`）は `644` で、ホスト側からも読み取り可能です。秘密鍵は SSH が利用できるよう `600`（所有者のみ読み書き可能）にし、編集はコンテナ内で行います。

## コンテナ稼働

```bash
docker compose up -d
```

## playbook設置

playbook はホスト側の `./playbooks` に配置します。`docker-compose.yml` で `./playbooks` をコンテナ内の `/ansible/playbooks` にマウントしているため、ホストで編集した playbook をコンテナ内からそのまま実行できます。

```bash
mkdir -p playbooks
docker compose exec ansible bash
cd /ansible/playbooks
```

## SSH鍵

コンテナ初回起動時に、以下が自動作成されます。実体はワークフォルダ内の `./ssh` に保存され、コンテナ内では `/root/.ssh` として見えます。

```bash
/root/.ssh/id_ed25519_ansible          # Ansible 接続用秘密鍵
/root/.ssh/id_ed25519_ansible.pub      # Ansible 接続用公開鍵
/root/.ssh/config                      # Ansible/ssh 用設定
```

既存の鍵がある場合は再作成しません。`config` は起動時に自動生成され、上書きされます。鍵を作り直す場合は `./ssh` を削除してから起動します。

### 秘密鍵を編集する場合

秘密鍵はホスト側で権限を広げず、コンテナに入って編集してください。既存の SSH 鍵に差し替える場合も同じ手順です。

```bash
docker compose exec --user root ansible bash
vim /root/.ssh/id_ed25519_ansible
chmod 600 /root/.ssh/id_ed25519_ansible
# 編集後の秘密鍵に対応する公開鍵を生成
ssh-keygen -y -f /root/.ssh/id_ed25519_ansible > /root/.ssh/id_ed25519_ansible.pub
chmod 644 /root/.ssh/id_ed25519_ansible.pub
exit
```

鍵を差し替えた場合は、新しい公開鍵を接続先に登録してください。

### 公開鍵認証で使う場合

ターゲットマシンの `~/.ssh/authorized_keys` に `/root/.ssh/id_ed25519_ansible.pub` の内容を登録します。

```bash
docker compose exec ansible ssh-copy-id -i /root/.ssh/id_ed25519_ansible.pub <ユーザー名>@<ターゲットホスト/IPアドレス>
```

ターゲット側の権限は以下を基本にします。

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## playbook稼働

```bash
docker compose exec ansible bash
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
<ターゲットのホスト名> ansible_host=<IPアドレス>
```

`ansible_user` はターゲットマシンに存在し、公開鍵を登録したユーザー名に合わせてください。例えば `root` ユーザーの `~/.ssh/authorized_keys` に公開鍵を登録した場合は、以下のように変更します。

```bash
[all:vars]
ansible_user=root
ansible_ssh_private_key_file=/root/.ssh/id_ed25519_ansible
ansible_python_interpreter=/usr/bin/python3
```

`Permission denied (publickey,...)` が出る場合は、接続先ユーザー名と公開鍵の登録先ユーザーが一致しているか確認してください。

## コンテナ停止

```bash
docker compose down
```

## 関連Qiita記事

- [個別記事から未紹介だった公開GitHubリポジトリを整理してみた](https://qiita.com/naritomo08/items/1620081b4363c3d0b400)
