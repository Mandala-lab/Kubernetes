#!/bin/sh

set -o posix errexit -o pipefail

# 对于 CentOS 8
yum update -y && yum -y install wget psmisc vim net-tools nfs-utils telnet yum-utils device-mapper-persistent-data lvm2 git network-scripts tar curl
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

# 清理旧的安装信息
which kubeadm kubelet kubectl
hash -r

systemctl daemon-reload

systemctl enable --now kubelet
systemctl status kubelet

systemctl enable kubeadm
systemctl status kubeadm

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
