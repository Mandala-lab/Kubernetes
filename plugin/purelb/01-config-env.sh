#!/usr/bin/env bash

# https://purelb.gitlab.io/docs/install/install/

# TODO Configu ration kubeproxy
Kubeproxy Configu ration kubeproxy
--proxy-mode IPVS
--ipvs-strict-arp

cat <<EOF | sudo tee /etc/sysctl.d/k8s_arp.conf
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2

EOF
sudo sysctl --system
