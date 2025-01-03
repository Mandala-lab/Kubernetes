#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

sudo sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config;sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config;sudo systemctl restart sshd;passwd root
hostnamectl set-hostname node
apt update -y;apt full-upgrade -y
export VERSION="6.8.0-38"
sudo apt-get install -y linux-headers-$VERSION-generic
sudo apt-get install -y linux-image-$VERSION-generic
sudo apt-get install -y linux-modules-$VERSION-generic
sudo apt-get install -y linux-modules-extra-$VERSION-generic
sudo update-grub
sudo reboot

git clone --depth 1 https://github.com/Mandala-lab/cloud-native-deploy.git&
git clone --depth 1 https://github.com/Mandala-lab/Kubernetes.git&


cat > /etc/cloud/templates/hosts.debian.tmpl <<EOF
## template:jinja
{#
This file (/etc/cloud/templates/hosts.debian.tmpl) is only utilized
if enabled in cloud-config.  Specifically, in order to enable it
you need to add the following to config:
   manage_etc_hosts: True
-#}
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.debian.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg or cloud-config from user-data
#
{# The value '{{hostname}}' will be replaced with the local-hostname -#}
127.0.1.1 {{fqdn}} {{hostname}}
127.0.0.1 localhost node1
45.207.192.132 node1
45.207.192.133 node2
45.207.192.134 node3
45.207.192.135 node4
45.207.192.136 node5
45.207.195.158 node6
EOF

