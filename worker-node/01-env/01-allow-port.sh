#!/bin/bash

set -e -o posix -o pipefail

# 工作节点需要开启以下下端口:
# 协议	方向	端口范围	目的	使用者
# TCP	入站	10250	Kubelet API	自身, 控制面
# TCP	入站	30000-32767	NodePort Services†	所有

sudo ufw allow 10250/tcp
sudo ufw allow 30000:32767/tcp

set +x
