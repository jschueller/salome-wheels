#!/bin/sh

set -xe

echo "waiting for key..."
sleep 0.5
mkdir ~/.ssh
cat /appdata/id_ed25519.pub >> ~/.ssh/authorized_keys

mkdir /var/run/sshd
/usr/sbin/sshd -D
