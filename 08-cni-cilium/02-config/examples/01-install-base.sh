#!/usr/bin/env bash

#export DEVICES="eth0"


#cilium install --version $CILIUM_VERSION \
#--set k8sServiceHost=$HOST \
#--set k8sServicePort=$K8S_API_SERVER_PORT \
#--set cluster.name=$CLUSTER_NAME \
#--set cluster.id=$CLUSTER_ID \
#--set kubeProxyReplacement=true \
#--set nodeinit.enabled=true \
#--set rollOutCiliumPods=true \
#--set bpfClockProbe=true \

helm repo add cilium https://helm.cilium.io/
helm repo update

export DEVICES="enp0s5"
export HOST="192.168.3.160"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="1.15.0-rc.0"
export CLUSTER_NAME="prvite-kubernetes"
export CLUSTER_ID=1
helm install cilium cilium/cilium --version $CILIUM_VERSION \
--namespace kube-system \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set cluster.name=$CLUSTER_NAME \
--set cluster.id="$CLUSTER_ID" \
--set kubeProxyReplacement=true \
--set nodeinit.enabled=true \
--set rollOutCiliumPods=true \
--set routingMode=native \
--set tunnel=disabled \
--set loadBalancer.mode=dsr \
--set bpf.lbExternalClusterIP=true \
--set bpf.hostLegacyRouting=false \
--set bpf.masquerade=true \
--set operator.replicas=3 \
--set ipv4NativeRoutingCIDR=10.244.0.0/16 \
--set ipMasqAgent.config.nonMasqueradeCIDRs='{10.244.0.0/16,10.96.0.0/12}' \
--set ipMasqAgent.config.masqLinkLocal=false \
--set ipMasqAgent.config.masqLinkLocalIPv6=false \
--set bandwidthManager.enabled=true \
--set bandwidthManager.bbr=true \
