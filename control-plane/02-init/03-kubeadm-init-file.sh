#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o errexit -o pipefail

# Kubernetes要求net.bridge.bridge-nf-call-iptables = 1,但是为了使用Cilium,我们需要将其设置为0
# 使用 --ignore-preflight-errors=all  忽略预检错误net.bridge.bridge-nf-call-iptables = 0这个错误
# 不使用Cilium这个CNI则设置net.bridge.bridge-nf-call-iptables = 1
#--ignore-preflight-errors=all \
mkdir -p /etc/kubernetes/manifests
HOME="/home/kubernetes"
cd $HOME || exit
if kubeadm init phase preflight --dry-run --config kubeadm-init-conf.yaml; then
  echo "预检成功"
  # 安装
  kubeadm init \
  --config=kubeadm-init-conf.yaml \
  --upload-certs \
  --v=7

  rm -rf $HOME/.kube
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # shell自动完成
  apt-get install bash-completion
  ##or
  #yum install bash-completion
  type _init_completion
  source /usr/share/bash-completion/bash_completion

  # 命令补全
  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  sudo chmod a+r /etc/bash_completion.d/kubectl

  # 别名
  echo 'alias k=kubectl' >>~/.bashrc
  echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
  source ~/.bashrc
else
  echo "命令执行失败"
  kubeadm reset -f
fi
