#!/usr/bin/env bash


# Cilium Base Requirements
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_NET_CLS_BPF=y
CONFIG_BPF_JIT=y
CONFIG_NET_CLS_ACT=y
CONFIG_NET_SCH_INGRESS=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_USER_API_HASH=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_BPF=y
CONFIG_PERF_EVENTS=y
# Optional: Iptables-based Masquerading
CONFIG_NETFILTER_XT_SET=m
CONFIG_IP_SET=m
CONFIG_IP_SET_HASH_IP=m
# Optional: L7 and FQDN Policies
CONFIG_NETFILTER_XT_TARGET_TPROXY=m
CONFIG_NETFILTER_XT_TARGET_CT=m
CONFIG_NETFILTER_XT_MATCH_MARK=m
CONFIG_NETFILTER_XT_MATCH_SOCKET=m
# Optional: IPSec
CONFIG_XFRM=y
CONFIG_XFRM_OFFLOAD=y
CONFIG_XFRM_STATISTICS=y
CONFIG_XFRM_ALGO=m
CONFIG_XFRM_USER=m
CONFIG_INET{,6}_ESP=m
CONFIG_INET{,6}_IPCOMP=m
CONFIG_INET{,6}_XFRM_TUNNEL=m
CONFIG_INET{,6}_TUNNEL=m
CONFIG_INET_XFRM_MODE_TUNNEL=m
CONFIG_CRYPTO_AEAD=m
CONFIG_CRYPTO_AEAD2=m
CONFIG_CRYPTO_GCM=m
CONFIG_CRYPTO_SEQIV=m
CONFIG_CRYPTO_CBC=m
CONFIG_CRYPTO_HMAC=m
CONFIG_CRYPTO_SHA256=m
CONFIG_CRYPTO_AES=m
# Optional: Bandwidth Manager
CONFIG_NET_SCH_FQ=m

helm repo add cilium https://helm.cilium.io/
helm repo update
export DEVICES="ens160"
export HOST="192.168.3.160"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="1.15.1"
export CLUSTER_NAME="prvite-kubernetes"
export CLUSTER_ID="1"
helm install cilium cilium/cilium --version $CILIUM_VERSION \
--namespace kube-system \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set cluster.name=$CLUSTER_NAME \
--set cluster.id="$CLUSTER_ID" \
--set kubeProxyReplacement=true \
--set l2announcements.enabled=true \
--set externalIPs.enabled=true \
--set k8sClientRateLimit.qps=50 \
--set k8sClientRateLimit.burst=100

