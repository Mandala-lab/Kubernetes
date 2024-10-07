#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

rm -rf $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

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

# 由于集群节点通常按顺序初始化，因此 CoreDNS Pod 很可能都运行在第一个控制平面节点上。
# 为了提供更高的可用性，请在至少加入一个新节点后重新平衡 CoreDNS Pod:

kubectl rollout restart deployment coredns -n kube-system
