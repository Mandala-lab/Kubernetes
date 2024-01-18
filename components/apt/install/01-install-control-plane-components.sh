#!/bin/sh

set -x

# 清除旧安装
systemctl stop kubeadm
systemctl stop kubelet
systemctl stop kubectl
sudo apt purge -y kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-mark unhold kubeadm
sudo apt-mark unhold kubelet
sudo apt-mark unhold kubectl
sudo apt remove -y kubeadm kubelet kubectl
rm -rf /usr/local/bin/kube*
rm -rf /usr/bin/kube*
rm -rf /var/lib/kube*
rm -rf /etc/sysconfig/kubelet
rm -rf /etc/kubernetes
rm -rf /etc/apt/sources.list.d/kubernetes.list
rm -rf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.confkub
sudo apt autoremove -y

# 安装 kubeadm、kubelet
sudo apt install -y apt-transport-https ca-certificates curl
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$VERSION/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/$VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

apt update -y
apt install -y containerd conntrack socat kubelet kubeadm kubectl

# 配置 cgroup 驱动与CRI一致
cp /etc/sysconfig/kubelet{,.back}
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF

cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /etc/sysconfig/kubelet

# 清理旧的安装信息
which kubeadm kubelet kubectl
hash -r

systemctl daemon-reload

systemctl enable --now kubelet
#systemctl status kubelet

systemctl restart containerd

kubeadm version
kubelet --version
kubectl version --client

# 查看版本的详细视图
# kubectl version --client --output=yaml

# 注意：如果 ipvs 模式成功打开，您应该会看到 IPVS 代理规则（使用 ipvsadm ），例如
# ipvsadm -ln
# IP Virtual Server version 1.2.1 (size=4096)
# Prot LocalAddress:Port Scheduler Flags
#   -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
# TCP  10.0.0.1:443 rr persistent 10800
#   -> 192.168.0.1:6443             Masq    1      1          0

# 或类似的日志出现在 kube-proxy 日志中（例如， /tmp/kube-proxy.log 对于本地集群），当本地集群正在运行时：
# Using ipvs Proxier.
# While there is no IPVS proxy rules or the following logs occurs indicate that the kube-proxy fails to use IPVS mode:
# 虽然没有 IPVS 代理规则或出现以下日志，但表明 kube-proxy 无法使用 IPVS 模式：
# Can't use ipvs proxier, trying iptables proxier
# Using iptables Proxier.

set +x
