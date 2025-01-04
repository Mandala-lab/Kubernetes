#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

sudo add-apt-repository ppa:cappelikan/ppa

sudo apt update

sudo apt install mainline

mainline --install 6.8

# 安装完成重启
reboot

uname -r

# 修复
sudo apt --fix-broken install -y
