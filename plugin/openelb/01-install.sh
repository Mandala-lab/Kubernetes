#!/usr/bin/env bash

kubectl apply -f https://raw.githubusercontent.com/openelb/openelb/master/deploy/openelb.yaml

# 执行以下命令，查看状态是否 openelb-manager 为READY： 1/1和STATUS： Running。如果是，则表示OpenELB安装成功
kubectl get po -n openelb-system

# 预期值:
# NAME                               READY   STATUS      RESTARTS   AGE
# openelb-admission-create-tjsqm     0/1     Completed   0          41s
# openelb-admission-patch-n247f      0/1     Completed   0          41s
# openelb-manager-74c5467674-bx2wg   1/1     Running     0
