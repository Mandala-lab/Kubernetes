#!/bin/bash

cilium uninstall cilium -n kube-system
rm -rf /etc/cni/net.d/05-cilium.conflist
rm -rf /opt/cni/bin/cilium-cni
ifconfig cilium_netdown
ip link delete kube-cilium_netdown
ifconfig cilium_host down
ip link delete cilium_host
ifconfig cilium_vxlan down
ip link delete cilium_vxlan

# 删除crd
sudo kubectl get crd | grep cilium | awk '{print $1}' | xargs sudo kubectl delete crd

# 删除IPTables
iptables -t filter -F
iptables -t filter -X
iptables -t filter -Z
iptables -t raw -F
iptables -t raw -X
iptables -t raw -Z
iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z
iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -Z

sudo ipvsadm -C

# remove cilium
rm -rf /usr/local/bin/cilium
rm -rf /usr/bin/cilium

# 清理 CNI 配置
rm -rf /etc/cni/net.d/
#rm -rf /opt/cni/bin/
rm -rf /etc/sysctl.d/00-k8s-arp.conf
rm -rf /etc/sysctl.d/98-cilium.conf

# 清理网卡
sudo ip link list | grep lxc | awk '{print $2}' | cut -c 1-15 | xargs -I {} sudo ip link delete {}
sudo ip link list | grep cilium_net@cilium_host | awk '{print $2}' | cut -c 1-10 | xargs -I {} sudo ip link delete {}
sudo ip link list | grep cilium_host@cilium_net | awk '{print $2}' | cut -c 1-11 | xargs -I {} sudo ip link delete {}
sudo ip route flush proto bird # 更新路由

# bfp, 谨慎删除
rm -rf /etc/systemd/system/sys-fs-bpf.mount
