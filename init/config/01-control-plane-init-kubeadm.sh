#!/bin/sh

#set -x

HOME="/home/kubernetes"
mkdir -p $HOME
cd $HOME || exit

# 获取当前版本的Kubernetes组件的镜像列表
# 并且替换为国内的阿里云镜像进行下载
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
# registry.cn-hangzhou.aliyuncs.com/google_containers
kubeadm config images list --kubernetes-version $VERSION \
| sed 's|registry.k8s.io|crictl pull registry.aliyuncs.com/google_containers|g' \
> download_images.sh

sudo sh download_images.sh

# coredns/coredns:v1.11.1和pause:3.9一般都下载失败, 因为阿里云镜像没有. 需要手动从registry.k8s.io下载
# 也可以跳过该步骤, 因为init也会自动下载, 而且init阶段却很奇怪的就可以下载成功, 有兴趣可以研究
#crictl pull registry.k8s.io/pause:3.9&
#crictl pull registry.k8s.io/coredns/coredns:v1.11.1&

ls /var/run/containerd/
ls /run/containerd/

# 查看默认的kubelet的配置
kubeadm config print init-defaults --component-configs KubeletConfiguration

# 预检
netstat -tuln | grep 6443
netstat -tuln | grep 10259
netstat -tuln | grep 10257

lsof -i:6443 -t
lsof -i:10259 -t
lsof -i:10257 -t

# ARP, 适用于云下没有LoadBalancer支持的集群, 可选, 与purelb使用
#cat <<EOF | sudo tee /etc/sysctl.d/00-k8s-arp.conf
#net.ipv4.conf.default.arp_announce = 2
#net.ipv4.conf.lo.arp_announce = 2
#net.ipv4.conf.all.arp_ignore = 1
#net.ipv4.conf.all.arp_announce = 2
#net.bridge.bridge-nf-call-arptables = 1
#EOF
#sysctl -p /etc/sysctl.d/00-k8s-arp.conf
#cat /etc/sysctl.d/00-k8s-arp.conf

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
else
  echo "命令执行失败"
  kubeadm reset -f
fi

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
#set +x
