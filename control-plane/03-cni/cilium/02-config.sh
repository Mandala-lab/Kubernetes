#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

# https://docs.cilium.io/en/v1.16/operations/performance/tuning/#netkit
CONFIG_PREEMPT_NONE=y

# tuned network-* 配置文件
apt install tuned -y
tuned-adm profile network-latency

# 将 CPU 调节器设置为 performance, 有些云厂商禁止

# 停止 irqbalance 并将 NIC 中断固定到特定的 CPU
#systemctl status irqbalance
#killall irqbalance
#cat > ./irqbalance.sh <<EOF
##!/bin/sh
##
## setting up irq affinity according to /proc/interrupts
## 2008-11-25 Robert Olsson
## 2009-02-19 updated by Jesse Brandeburg
## 2010-09-15 Jesper Dangaard Brouer, change script for Debian ifup
##
## > Dave Miller:
## (To get consistent naming in /proc/interrups)
## I would suggest that people use something like:
##	char buf[IFNAMSIZ+6];
##
##	sprintf(buf, "%s-%s-%d",
##	        netdev->name,
##		(RX_INTERRUPT ? "rx" : "tx"),
##		queue->index);
##
##  Assuming a device with two RX and TX queues.
##  This script will assign:
##
##	eth0-rx-0  CPU0
##	eth0-rx-1  CPU1
##	eth0-tx-0  CPU0
##	eth0-tx-1  CPU1
##
#
#export OUT=/tmp/ifup-set-irq-affinity-DEBUG
#DEBUG=$VERBOSITY
#DEBUG=1 #Force debugging on
#info() {
#    if [ -n "$DEBUG" -a "$DEBUG" -ne 0 ]; then
#	TS=`date +%Y%m%dT%H%M%S`
#	echo "$TS iface:$IFACE -- $@" >> $OUT
#    fi
#}
#
#set_affinity()
#{
#    MASK=$((1<<$VEC))
#    printf "%s mask=%X for /proc/irq/%d/smp_affinity\n" $DEV $MASK $IRQ >> $OUT
#    printf "%X" $MASK > /proc/irq/$IRQ/smp_affinity
#    #echo $DEV mask=$MASK for /proc/irq/$IRQ/smp_affinity
#    #echo $MASK > /proc/irq/$IRQ/smp_affinity
#}
#
#if [ "$IFACE" = "" ] ; then
##	echo "Description:"
##	echo "    This script attempts to bind each queue of a multi-queue NIC"
##	echo "    to the same numbered core, ie tx0|rx0 --> cpu0, tx1|rx1 --> cpu1"
##	echo "Usage: Is called by the ifup scripts"
##	echo "    And expect environment variable \$IFACE is set"
##	echo ""
##	echo "Allowing you the set IFACE as arg1"
#	if [ -n "$1" ]; then
#	    IFACE=$1
#	fi
##	echo "Using IFACE: $IFACE"
#fi
#info "Start set_irq_affinity"
#
## check for irqbalance running
#IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
#if [ "$IRQBALANCE_ON" = "0" ] ; then
#	echo " WARNING: irqbalance is running and will"
#	echo "          likely override this script's affinitization."
#	echo "          Please stop the irqbalance service and/or execute"
#	echo "          'killall irqbalance'"
#fi
#
##
## FIXME: We have problem with devices with VLAN interfaces as the
## device is not taken "ifconfig up", until the first VLAN device is
## activated.
##
## TODO/IDEA: Add a hack for VLAN interfaces, which selects the
## underlying device.
##
#
##
## Set up the desired devices.
##
#
#for DEV in $IFACE
#do
#  for DIR in rx tx TxRx
#  do
#     MAX=`grep $DEV-$DIR /proc/interrupts | wc -l`
#     if [ "$MAX" = "0" ] ; then
#       MAX=`egrep -i "$DEV:.*$DIR" /proc/interrupts | wc -l`
#     fi
#     if [ "$MAX" = "0" ] ; then
#       info no $DIR vectors found on $DEV
#       continue
#       #exit 1
#     fi
#     for VEC in `seq 0 1 $MAX`
#     do
#        IRQ=`cat /proc/interrupts | grep -i $DEV-$DIR-$VEC"$"  | cut  -d:  -f1 | sed "s/ //g"`
#        if [ -n  "$IRQ" ]; then
#          set_affinity
#        else
#           IRQ=`cat /proc/interrupts | egrep -i $DEV:v$VEC-$DIR"$"  | cut  -d:  -f1 | sed "s/ //g"`
#           if [ -n "$IRQ" ]; then
#             set_affinity
#           fi
#        fi
#     done
#  done
#done
#EOF
#chmod +x ./irqbalance.sh && ./irqbalance.sh

## 使用 systemd 挂载BPFFS 由于 systemd 挂载的方式 文件系统，挂载点路径必须反映在 unit filename 中。
#cat <<EOF | sudo tee /etc/systemd/system/sys-fs-bpf.mount
#[Unit]
#Description=Cilium BPF mounts
#Documentation=https://docs.cilium.io/
#DefaultDependencies=no
#Before=local-fs.target umount.target
#After=swap.target
#
#[Mount]
#What=bpffs
#Where=/sys/fs/bpf
#Type=bpf
#Options=rw,nosuid,nodev,noexec,relatime,mode=700
#
#[Install]
#WantedBy=multi-user.target
#EOF

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
