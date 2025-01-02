#!/usr/bin/env bash

#wget -t 2 -T 240 -N -S https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
mkdir -pv /home/kubernetes/flannel
cd /home/kubernetes/flannel
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f kube-flannel.yml
