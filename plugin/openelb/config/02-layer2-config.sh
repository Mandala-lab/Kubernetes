#!/usr/bin/env bash

#!/usr/bin/env bash
# 适用于Kube-Proxy的第 2 层模式

# 资料
## https://openelb.io/docs/getting-started/usage/use-openelb-in-layer-2-mode/
## https://juejin.cn/post/7313728275787808808

# 先决条件
## 您需要准备一个已安装 OpenELB 的 Kubernetes 集群。所有 Kubernetes 集群节点必须位于同一第 2 层网络（在同一路由器下）。
## 您需要准备一台客户端机器，用于验证OpenELB在二层模式下是否正常运行。客户端计算机需要与 Kubernetes 群集节点位于同一网络上。
## 第 2 层模式要求您的基础架构环境允许匿名 ARP/NDP 数据包。如果 OpenELB 安装在基于云的 Kubernetes 集群中进行测试，您需要与云供应商确认是否允许匿名 ARP/NDP 数据包。否则，无法使用第 2 层模式。

# TODO 前提条件
kubectl edit configmap kube-proxy -n kube-system
## 修改为：
ipvs:
  strictARP: true

kubectl rollout restart daemonset kube-proxy -n kube-system

# 执行以下命令，对master1进行注解，指定网卡
export NODE_NAME=master1
export NODE_IP=192.168.0.2
kubectl annotate nodes $NODE_NAME layer2.openelb.kubesphere.io/v1alpha1=$NODE_IP

# 配置文件
export INTERFACE="ens160"
export IP_RANGE="192.168.0.180-192.168.2.190"
cat > layer2-eip.yaml <<EOF
# Source: layer2-eip.yaml
apiVersion: network.kubesphere.io/v1alpha2
kind: Eip
metadata:
  name: eip-pool
  eip.openelb.kubesphere.io/is-default-eip: "true"
spec:
  address: $IP_RANGE
  protocol: layer2
  disable: false
  interface: INTERFACE
EOF

kubectl apply -f layer2-eip.yaml
