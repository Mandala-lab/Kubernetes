#!/bin/bash

set -e -o posix -o pipefail

HOME="/home/kubernetes"
mkdir -p $HOME
cd $HOME || exit

# 获取当前版本的Kubernetes组件的镜像列表
# 并且替换为国内的阿里云镜像进行下载
#VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
# VERSION=v1.30.1
# registry.cn-hangzhou.aliyuncs.com/google_containers
#kubeadm config images list --kubernetes-version $VERSION \
#| sed 's|registry.k8s.io|crictl pull registry.aliyuncs.com/google_containers|g' \
#> download_images.sh
#
#sudo sh download_images.sh

# coredns/coredns:v1.11.1和pause:3.9一般都下载失败, 因为阿里云镜像没有. 需要手动从registry.k8s.io下载
# 也可以跳过该步骤, 因为init也会自动下载, 而且init阶段却很奇怪的就可以下载成功, 有兴趣可以研究
#crictl pull registry.k8s.io/pause:3.9&
#crictl pull registry.k8s.io/coredns/coredns:v1.11.1&

ls /var/run/containerd/
ls /run/containerd/

# 查看默认的kubelet的配置
kubeadm config print init-defaults --component-configs \
KubeProxyConfiguration,KubeletConfiguration > kubeadm-config.yaml

# 预检
netstat -tuln | grep 6443
netstat -tuln | grep 10259
netstat -tuln | grep 10257

lsof -i:6443 -t
lsof -i:10259 -t
lsof -i:10257 -t

