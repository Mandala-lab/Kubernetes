#!/bin/sh

set -o posix errexit -o pipefail

# 控制节点需要开启以下下端口:
# 协议	方向	端口范围	目的	使用者
# TCP	入站	6443	Kubernetes API server	所有
# TCP	入站	2379-2380	etcd server client API	kube-apiserver, etcd
# TCP	入站	10250	Kubelet API	自身, 控制面
# TCP	入站	10259	kube-scheduler	自身
# TCP	入站	10257	kube-controller-manager	自身
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10259/tcp
sudo ufw allow 10257/tcp

set +x
