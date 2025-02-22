#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail
sudo apt install -y vim
sudo sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo passwd root
hostnamectl set-hostname node
apt update -y;apt full-upgrade -y

export VERSION="6.8.0-38"
sudo apt-get install -y linux-headers-$VERSION-generic
sudo apt-get install -y linux-image-$VERSION-generic
sudo apt-get install -y linux-modules-$VERSION-generic
sudo apt-get install -y linux-modules-extra-$VERSION-generic
sudo update-grub
sudo reboot

git clone --depth 1 https://github.com/Mandala-lab/cloud-native-deploy.git
git clone --depth 1 https://github.com/Mandala-lab/Kubernetes.git

cat > /etc/hosts <<EOF
127.0.0.1 localhost
192.168.3.100 node1
192.168.3.102 node2
192.168.3.103 node3
EOF
