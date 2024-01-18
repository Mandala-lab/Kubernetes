#!/usr/bin/env bash

set -x
# -e：如果任何命令的退出状态是非零值，脚本将立即退出。
# -u：当使用未定义的变量时，脚本将立即退出。
# -x：在执行每个命令之前，将命令及其参数输出到标准错误输出。
# -o pipefail：如果管道中的任何命令失败，整个管道的退出状态将是失败状态。

# 验证每个节点的 MAC 地址和product_uuid是否唯一](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address
sudo cat /sys/class/dmi/id/product_uuid

# 设置为静态路由
# Ubuntu示例:
## DNS的IP地址， 需要自己填
#export DNS_IP="192.168.3.1"
#export NEXT_ROUTE="192.168.3.1"
#export CIDR="192.168.3.152/24"
#export INTERFACE="enp0s5"
## 当前服务器的IP与子网掩码地址
##CIDR=$(ip -o -4 addr show | awk '$2 ~ /^(eth|en)/ {print $4}')
## 网卡的接口名
#INTERFACE=$(ip -o link show | awk -F': ' '$2 ~ /^(eth|en)/ {print $2}')
#
#cp /etc/netplan/00-installer-config.yaml{,.back}
#cat > /etc/netplan/00-installer-config.yaml <<EOF
## 参考: https://ubuntuforums.org/showthread.php?t=2491245&p=14159782
#network:
#  version: 2
#  renderer: networkd
#  ethernets:
#    $INTERFACE: # 网卡名称
#      dhcp4: false # 是否启用IPV4的DHCP
#      dhcp6: false # 是否启用IPV6的DHCP
#      addresses: # 网卡的IP地址和子网掩码。例如，192.168.2.152/24 表示IP地址为192.168.2.152，子网掩码为255.255.255.0
#        - $CIDR
#      nameservers: # 用于指定DNS服务器地址的部分
#          addresses: # 列出DNS服务器的IP地址
#            #- 114.114.114.114
#            - $DNS_IP
#      routes: # 配置静态路由
#          - to: 0.0.0.0/0 # 目标网络地址，default 表示默认路由
#            via: $NEXT_ROUTE # 指定了路由数据包的下一跳地址，192.168.2.1 表示数据包将通过该地址进行路由
#            metric: 100 # 指定了路由的优先级，数值越小优先级越高
#            on-link: true # 表示数据包将直接发送到指定的下一跳地址，而不需要经过网关
#      mtu: 1500 # 最大传输单元（MTU），表示网络数据包的最大尺寸
#EOF
#cat /etc/netplan/00-installer-config.yaml
## Netplan配置文件不应该对其他用户开放访问权限 过于开放的权限，这可能会导致安全风险
#sudo chmod 600 /etc/netplan/00-installer-config.yaml
## 生成和应用更改
#sudo netplan generate
#sudo netplan apply

#  时间同步
apt install ntpdate -y # Ubuntu
ntpdate time.windows.com

# runc 是操作系统级别的软件包, 用于与Containerd Docker Podman等CRI底层的OCI工具
# Containerd -> runc
# 少数情况下, 系统可能没有安装runc或者配置不正确
# 二进制:
VERSION="v1.1.11"

ARCH=""
# 使用uname -m获取架构信息
machine=$(uname -m)
# 判断架构信息并设置变量的值
if [ "$machine" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$machine" = "x86_64" ]; then
    ARCH="amd64"
else
    echo "请手动定义你的发行版的架构"
fi
echo $ARCH
wget https://github.com/opencontainers/runc/releases/download/${VERSION}/runc.${ARCH}
install -m 755 ./runc.${ARCH} /usr/local/sbin/runc

rm -rf ./runc.${ARCH}
# 包管理器:
# apt install -y runc

# 设置控制节点与工作节点

# 修改Hosts
#cat >> /etc/hosts << EOF
#192.168.2.152 node-152
#192.168.2.155 node-155
#192.168.2.158 node-158
#192.168.2.160 node-160
#192.168.2.100 node-100
#192.168.2.101 node-101
#192.168.2.102 node-102
#EOF

# systemd-resolved
systemctl restart systemd-resolved
#systemctl status systemd-resolved

# 关闭SELinux
sudo setenforce 0 # 临时禁用, 重启变回
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config # 禁用

# SWAP分区,
# kubelet 的默认行为是: 如果在节点上检测到交换内存，则无法启动。自 v1.22 起支持 Swap。
# 从 v1.28 开始，只有 `cgroup v2` 支持 Swap
# kubelet 的 NodeSwap 特性门控是 beta 版，但默认处于禁用状态, 允许 kubelet 在节点上使用 swap
#
sed -i '/^\/.*swap/s/^/#/' /etc/fstab
sudo mount -a
sudo swapoff -a
cat /etc/fstab
grep swap /etc/fstab
# sleep 4
# 检查是否存在swap分区
sudo blkid | grep swap
# sleep 4
# 执行命令并获取输出
#result=$(cat /proc/swaps)
## 判断输出是否为0，如果不是则退出
#if [ "$result" -ne 0 ]; then
#    echo "Swap 存在，退出脚本"
#    exit 1
#fi
## 如果输出为0，则继续执行脚本的其他部分
#echo "Swap 不存在，继续执行脚本"
# free -m

# 创建/etc/sysctl.d/99-kubernetes-cri.conf配置文件
# cilium不需要
# 在文件名/etc/sysctl.d/99-kubernetes-cri.conf中，“99” 代表文件的优先级或顺序。
# sysctl是Linux内核参数的配置工具，它可以通过修改/proc/sys/目录下的文件来设置内核参数。
# 在/etc/sysctl.d/目录中，可以放置一系列的配置文件，以便在系统启动时自动加载这些参数。
# 这些配置文件按照文件名的字母顺序逐个加载。数字前缀用于指定加载的顺序，较小的数字表示较高的优先
# 参数说明:
# 启用控制 IPv4 数据包经过桥接时是否要经过 iptables 过滤
# 启用控制 IPv6 数据包经过桥接时是否要经过 ip6tables 过滤
# 启用 IPv4 数据包的转发功能
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
# net.bridge.bridge-nf-call-iptables  = 1
# net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
#使配置生效:
sysctl -p /etc/sysctl.d/99-kubernetes-cri.conf

# 通过运行以下命令验证是否加载了`br_netfilter`，`overlay`模块：
ehco "通过运行以下命令验证是否加载了`br_netfilter`，`overlay`模块"
lsmod | grep br_netfilter
lsmod | grep overlay

# IPVS 待测试
#apt install ipset ipvsadm -y
#
#mkdir -p /etc/sysconfig/ipvsadm
#cat > /etc/sysconfig/ipvsadm/ipvs.modules <<EOF
##!/bin/bash
#modprobe -- ip_vs
#modprobe -- ip_vs_rr
#modprobe -- ip_vs_wrr
#modprobe -- ip_vs_sh
#modprobe -- nf_conntrack
#EOF
# 授权、运行、检查是否加载
#chmod 755 /etc/sysconfig/ipvsadm/ipvs.modules && bash /etc/sysconfig/ipvsadm/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack

# 由于ipvs已经加入到了内核的主干，所以为kube-proxy开启ipvs的前提需要加载以下的内核模块：
#cat > /etc/modules-load.d/ipvs.conf << EOF
#ip_vs
#ip_vs_rr
#ip_vs_wrr
#ip_vs_sh
#nf_conntrack
#EOF
#modprobe ip_vs
#modprobe ip_vs_rr
#modprobe ip_vs_wrr
#modprobe ip_vs_sh
# 使用命令查看是否已经正确加载所需的内核模块:
#lsmod | grep -e ip_vs -e nf_conntrack

#systemctl restart systemd-modules-load.service
#
#lsmod | grep -e ip_vs -e nf_conntrack
#cut -f1 -d " "  /proc/modules | grep -e ip_vs -e nf_conntrack

echo "/etc/sysctl.d/99-kubernetes-cri.conf:"
cat /etc/sysctl.d/99-kubernetes-cri.conf

#echo "blkid | grep swap: 为空就正常"
#sudo blkid | grep swap

set +x
