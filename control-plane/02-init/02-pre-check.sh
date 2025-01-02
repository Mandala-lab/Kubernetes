#!/bin/bash

set -e -o posix -o pipefail

HOME="/home/kubernetes"
mkdir -p $HOME
cd $HOME || exit

# 国内阿里代理: registry.cn-hangzhou.aliyuncs.com/google_containers
declare proxy=""
declare VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy=*)
      proxy="${1#*=}"
      ;;
    --VERSION=*)
      VERSION="${1#*=}"
      ;;
    *)
    echo "未知的命令行选项参数: $1"
    exit 1
    ;;
  esac
  shift
done

if [[ $proxy != "" ]]; then
  echo "获取当前版本的Kubernetes组件的镜像列表"
  echo "并且替换为国内的阿里云镜像进行下载"

  kubeadm config images list --kubernetes-version "$VERSION" \
  > download_images.sh
  sed -i 's|registry.k8s.io|crictl pull registry.aliyuncs.com/google_containers|g' download_images.sh

  sudo sh download_images.sh
fi

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
apt install net-tools
netstat -tuln | grep 6443
netstat -tuln | grep 10259
netstat -tuln | grep 10257

lsof -i:6443 -t
lsof -i:10259 -t
lsof -i:10257 -t

