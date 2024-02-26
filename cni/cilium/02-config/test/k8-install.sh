cp /etc/sysctl.conf{,back}
cat >> /etc/sysctl.conf <<EOF
net.ipv4.tcp_slow_start_after_idle=0
net.core.rmem_max=16777216
fs.inotify.max_user_watches=524288
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
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_max_syn_backlog=8096
net.bridge.bridge-nf-call-arptables=1
net.ipv4.tcp_rmem=4096 12582912 16777216
vm.swappiness=0
kernel.sysrq=1
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_synack_retries=2
#net.ipv6.conf.lo.disable_ipv6=1
#net.ipv6.conf.all.disable_ipv6=1
#net.ipv6.conf.default.disable_ipv6=1
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
EOF

# nofile：
# soft limit: 最大可打开的文件句柄数。设置为 655350，意味着允许打开655350个文件句柄。
# hard limit: 硬限制，不能被用户或程序超过。也设置为 655350。
# nproc：
# soft limit: 允许创建的最大进程数。设置为 655350，意味着允许创建655350个进程。
# hard limit: 硬限制，不能被用户或程序超过。也设置为 655350。
# core： 核心：
# soft limit: 允许的最大core文件大小。设置为 unlimited，意味着没有限制。
# hard limit: 硬限制，不能被用户或程序超过。也设置为 unlimited。
cp /etc/security/limits.conf{,back}
cat >> /etc/security/limits.conf  <<EOF
*   soft    nofile  655350
*   hard    nofile655350
*   soft    nproc   655350
*   hard    nproc   655350
*   soft    core    unlimited
*   hard    core    unlimited
EOF

sed -i "s#4096#655350#g" /etc/security/limits.d/20-nproc.conf
# 该 shell 环境中登录并执行命令的用户设置资源限制
# - 将最大用户进程数（软限制）设置为 65535
# - 将打开的文件描述符的最大数量（软限制）设置为 65535
# - 将核心转储文件的最大大小（硬限制）设置为无限制
# - 核心转储是进程终止时内存的快照
# - 将最大驻留内存大小（软限制）设置为无限制
# - 将进程堆栈段的最大大小（软限制）设置为无限制
# - 将进程的虚拟内存的最大大小（软限制）设置为无限制
# - 将最大 CPU 时间（软限制）设置为无限制
# - 将核心转储文件的最大数量（软限制）设置为无限制
cp /etc/profile{,back}
cat >> /etc/profile <<EOF
ulimit -u 65535
ulimit -n 65535
ulimit -d unlimited
ulimit -m unlimited
ulimit -s unlimited
ulimit -v unlimited
ulimit -t unlimited
ulimit -c unlimited
EOF

## 加载内核
if [ -f /etc/sysconfig/modules/ipvs.modules ];then
    rm -f /etc/sysconfig/modules/ipvs.modules
fi
touch /etc/sysconfig/modules/ipvs.modules
chmod +x /etc/sysconfig/modules/ipvs.modules

cat > ipvs.sh <<EOF
ipvs_mods_dir="/usr/lib/modules/`uname -r`/kernel/net/netfilter/ipvs"
for i in \$(ls \$ipvs_mods_dir|grep -o "^[^.]*" )
do
  /sbin/modinfo -F filename \$i &>/dev/null
  if [ \$? -eq 0 ];then
        /sbin/modprobe \$i
        echo "/sbin/modprobe \$i" >> /etc/sysconfig/modules/ipvs.modules
  fi
done
EOF

## 加载ipvs模块
sh ipvs.sh
## 验证
lsmod |grep ip

source /etc/profile

sysctl -p
