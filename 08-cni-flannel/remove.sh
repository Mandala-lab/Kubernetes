#!/usr/bin/env bash

kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

apt install net-tools # Ubuntu
yum install net-tools # RedHat

ifconfig flannel.1 down
ip link delete flannel.1
