# ansible-docker

ansibleを稼働するコンテナ

## コンテナ稼働

```
docker-compose up -d
```

## playbook設置

playbooksフォルダ内に動かしたいplaybookを置く。
一回コンテナ起動しないと本フォルダは作られない。

## ansible SSH公開鍵配布

コンテナ稼働後、以下の手順でSSH鍵を作成し、
公開鍵をリモートで動かしたいマシンの"~/.ssh/authorized_keys"ファイルに書き込み、
パーミッションを600にする。

```
cd ssh
ssh-keygen -t ed25519 -C "ansible-docker" -f id_ed25519_ansible
→途中でパスワード聞かれるが、空パスワードでいい。
chmod 700 .
chmod 600 id_ed25519_ansible
chmod 600 id_ed25519_ansible.pub
```

公開鍵の配布について、以下の方法でもよい。
ただし、相手のマシンがパスワードによるSSHログインを許可している場合。

```
ssh-copy-id -i ssh/id_ed25519_ansible.pub <ユーザー名>@<ターゲットホスト/IPアドレス>
```

## playbook稼働

```
docker-compose exec ansible sh
ansible-playbook ...

以下のコマンドで動作確認可能。
ターゲットノードへの公開鍵配布とターゲットIP／ホストを記載したhosts.iniファイルを作成すること。
ansible all -i hosts.ini -m ping
```

inventory(hosts.ini)について、以下の設定を基本として作成すること。

```
[all:vars]
ansible_user=naritomo
ansible_ssh_private_key_file=/root/.ssh/id_ed25519_ansible
ansible_python_interpreter=/usr/bin/python3

[ansible_hosts]
<ターゲットのホスト名・IPアドレス>
```

## コンテナ停止

```
docker-compose down
```
