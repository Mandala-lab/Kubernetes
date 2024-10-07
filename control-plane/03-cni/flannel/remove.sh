#!/usr/bin/env bash

kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

yum install net-tools # RedHat
apt install net-tools # Ubuntu

ifconfig flannel.1 down
ip link delete flannel.1
