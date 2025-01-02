#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

# https://docs.cilium.io/en/v1.16/operations/system_requirements/#admin-system-reqs

# 为了正确启用 eBPF 功能，必须启用以下内核配置选项。Distribution Kernel 通常就是这种情况。当选项可以构建为模块或静态链接时，任何选择都是有效的。
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
CONFIG_SCHEDSTATS=y

# L7 和 FQDN 策略的要求
# L7 proxy redirection currently uses TPROXY iptables actions as well as socket matches. For L7 redirection to work as intended kernel configuration must include the following modules:
# L7 代理重定向目前使用 TPROXY iptables 操作以及套接字匹配。要使 L7 重定向按预期工作，内核配置必须包括以下模块：

CONFIG_NETFILTER_XT_TARGET_TPROXY=m
CONFIG_NETFILTER_XT_TARGET_MARK=m
CONFIG_NETFILTER_XT_TARGET_CT=m
CONFIG_NETFILTER_XT_MATCH_MARK=m
CONFIG_NETFILTER_XT_MATCH_SOCKET=m

# IPsec 要求
# IPsec 透明加密功能需要许多内核配置选项，其中大多数选项用于启用实际加密。请注意，所需的特定选项取决于算法。以下列表对应于 GCM-128-AES 的要求。

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

#带宽管理器需要以下内核配置选项来更改数据包调度算法。
CONFIG_NET_SCH_FQ=m
