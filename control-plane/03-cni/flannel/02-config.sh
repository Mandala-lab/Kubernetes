#!/usr/bin/env bash


# 如果是flannel插件, 需要修改flannel的yaml文件的net-conf.json为当前的podSubnet值


kubectl apply -f kube-flannel.yml

# 需要把反斜杠/前面加上\, 不然正则表达式会错误识别
export POD_CIDR="10.10.0.0\/18"

sed -i "s/10.244.0.0\/16/${POD_CIDR}/g" kube-flannel.yml

kubectl get po,svc -n flannel-system -owide
