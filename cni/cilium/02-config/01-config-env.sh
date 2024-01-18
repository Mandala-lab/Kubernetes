#!/usr/bin/env bash

# 备份
cp /boot/config-$(uname -r){,.back}

# 查看:
cat /boot/config-$(uname -r) | grep CONFIG_BPF
cat /boot/config-$(uname -r) | grep CONFIG_BPF_SYSCALL
cat /boot/config-$(uname -r) | grep CONFIG_NET_CLS_BPF
cat /boot/config-$(uname -r) | grep CONFIG_BPF_JIT
cat /boot/config-$(uname -r) | grep CONFIG_NET_CLS_ACT
cat /boot/config-$(uname -r) | grep CONFIG_NET_SCH_INGRESS
cat /boot/config-$(uname -r) | grep CONFIG_CRYPTO_SHA1
cat /boot/config-$(uname -r) | grep CONFIG_CRYPTO_USER_API_HASH
cat /boot/config-$(uname -r) | grep CONFIG_CGROUPS
cat /boot/config-$(uname -r) | grep CONFIG_CGROUP_BPF
cat /boot/config-$(uname -r) | grep CONFIG_PERF_EVENTS
cat /boot/config-$(uname -r) | grep CONFIG_SCHEDSTATS

# 为了正确启用 eBPF 功能，必须启用以下内核配置选项。分发内核通常就是这种情况
# 当一个选项可以构建为模块或静态链接时，任何一个选择都是有效的
# https://docs.cilium.io/en/v1.15.0-rc.0/operations/system_requirements/#admin-system-reqs
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

# 如果不使用 BPF 进行伪装（ enable-bpf-masquerade=false ，默认值），那么您将需要以下内核配置选项。
#CONFIG_NETFILTER_XT_SET=m
#CONFIG_IP_SET=m
#CONFIG_IP_SET_HASH_IP=m

# 带宽管理器需要以下内核配置选项来更改数据包调度算法
# https://docs.cilium.io/en/v1.15.0-rc.0/operations/system_requirements/#admin-system-reqs
cat /boot/config-$(uname -r) | grep CONFIG_NET_SCH_FQ
CONFIG_NET_SCH_FQ=m

# 使用 systemd 安装 BPFFS
# https://docs.cilium.io/en/v1.15.0-rc.0/operations/system_requirements/#admin-system-reqs
# https://docs.cilium.io/en/v1.15.0-rc.0/network/kubernetes/configuration/#bpffs-systemd
cat <<EOF | sudo tee /etc/systemd/system/sys-fs-bpf.mount
[Unit]
Description=Cilium BPF mounts
Documentation=https://docs.cilium.io/
DefaultDependencies=no
Before=local-fs.target umount.target
After=swap.target

[Mount]
What=bpffs
Where=/sys/fs/bpf
Type=bpf
Options=rw,nosuid,nodev,noexec,relatime,mode=700

[Install]
WantedBy=multi-user.target
EOF
cat /etc/systemd/system/sys-fs-bpf.mount
sysctl -p /etc/systemd/system/sys-fs-bpf.mount
sysctl --system

# 私有云使用类型PureLB的本地的LoadBalance时需要这些参数
cat > /etc/sysctl.d/96-cilium.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
# net.ipv4.conf.lxc*.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
# net.ipv4.conf.*.rp_filter = 0
EOF
sysctl -p /etc/sysctl.d/96-cilium.conf

# 允许gdb附加到进程用户空间进行调试
# sudo sed -i 's/kernel.yama.ptrace_scope = [12]/kernel.yama.ptrace_scope = 0/g' /etc/sysctl.d/10-ptrace.conf

# https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#network-plugin-requirements
# 对于插件开发者和经常构建或部署 Kubernetes 的用户，插件可能还需要特定的配置来支持 kube-proxy。
# iptables 代理依赖于 iptables，插件可能需要确保容器流量可供 iptables 使用。
# 例如，如果插件将容器连接到 Linux 桥接器，则插件必须将 net/bridge/bridge-nf-call-iptables sysctl 设置为 1
# 以确保 iptables 代理正常运行。如果插件不使用 Linux 桥接器，而是使用 Open vSwitch 或其他机制，则应确保为代理正确路由容器流量。
# net.bridge.bridge-nf-call-iptables=1
# net.bridge.bridge-nf-call-ip6tables=1

cat > /etc/sysctl.d/97-kubernetes-cilium-sysctl.conf <<EOF
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).
net.ipv4.tcp_slow_start_after_idle=0
net.core.rmem_max=16777216
fs.inotify.max_user_watches=1048576
kernel.softlockup_all_cpu_backtrace=1
kernel.softlockup_panic=1
fs.file-max=2097152
fs.nr_open=2097152
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=16384
vm.max_map_count=262144
net.core.netdev_max_backlog=16384
net.ipv4.tcp_wmem=4096 12582912 16777216
net.core.wmem_max=16777216
net.core.somaxconn=32768
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=8096
# net.bridge.bridge-nf-call-iptables=1
# net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.tcp_rmem=4096 12582912 16777216
vm.swappiness=0
kernel.sysrq=1
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.conf.all.route_localnet=1
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_synack_retries=2
net.ipv6.conf.lo.disable_ipv6=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.all.forwarding=0
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_probes=10
net.ipv4.tcp_keepalive_intvl=30
net.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_tcp_timeout_established=180
net.netfilter.nf_conntrack_tcp_timeout_time_wait=120
net.netfilter.nf_conntrack_tcp_timeout_close_wait=60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=12
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_orphan_retries=3
kernel.pid_max=4194303
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=1
vm.min_free_kbytes=262144
kernel.msgmnb=65535
kernel.msgmax=65535
kernel.shmmax=68719476736
kernel.shmall=4294967296
kernel.core_uses_pid=1
net.ipv4.neigh.default.gc_thresh1=0
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh3=8192
net.netfilter.nf_conntrack_tcp_timeout_close=3
EOF

sysctl -p /etc/sysctl.d/97-kubernetes-cilium-sysctl.conf
sysctl --system
