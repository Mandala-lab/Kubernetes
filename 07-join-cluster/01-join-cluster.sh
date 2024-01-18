#!/bin/bash

# 此脚本在master节点执行

declare join_command
join_command=$(kubeadm token create --print-join-command)
echo "$join_command"
export WORKER_NODE=("192.168.2.155" "192.168.2.160" "192.168.2.100")
export USER="root"

for host in "${WORKER_NODE[@]}"
do
    ssh $USER@$host '$join_command'
done
