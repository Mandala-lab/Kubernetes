#!/usr/bin/env bash

kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

apt install net-tools # Ubuntu
yum install net-tools # RedHat

ifconfig flannel.1 down
ip link delete flannel.1

ifconfig kube-ipvs0 down
ip link delete kube-ipvs0

ifconfig cni0 down
ip link delete cni0

rm -rf /opt/cni/bin/flannel
rm -rf /etc/cni/net.d/10-flannel.conflist

sudo ip addr del 172.0.3.1/24 dev cni0;
sudo ip link del cni0
sudo rm -rf /etc/cni/net.d/*
sudo systemctl restart kubelet
ip a
