#!/usr/bin/env bash
#
# 配置Kubernetes所需要的基本依赖项, 例如内核参数, 启用和使用社区广泛推荐的内核参数

set -e -o posix -o pipefail -x

while [ "$#" -gt 0 ]; do
    case "$1" in
        --trace=*)
            trace=true
            shift
            ;;
        *)  # 处理未知选项
            echo "Error: Unsupported argument $1."
            exit 1
            ;;
    esac
done

# 运行前清理
pre_clear(){
  declare describe="运行前清理"
  echo $describe

  if [ -f /etc/security/limits.conf.back ];then
    mv /etc/security/limits.conf{.back,}
  fi
  if [ -f /etc/profile.back ];then
    mv /etc/profile{.back,}
  fi
  if [ -f /etc/hosts.back ];then
    mv /etc/hosts{.back,}
  fi
  if [ -f /etc/fstab.back ];then
    mv /etc/fstab{.back,}
  fi

  rm -rf /etc/sysctl.d/99-kubernetes-cri.conf
}

# TODO
# Function: set_static_route
# Description: 设置静态路由
# Parameters:
#   $1 - DNS_IP
#   $2 - GATEWAY_IP
#   $3 - CIDR
#   $4 - INTERFACE
# Returns: None
set_static_route() {
  local describe="设置静态路由"
  echo $describe

  local GATEWAY_IP="192.168.3.1"
  local ADDRESSES="192.168.3.152/24"
  local INTERFACE="enp0s5"

  # 当前服务器的IP与子网掩码地址
  ADDRESSES=$(ip -o -4 addr show | awk '$2 ~ /^(eth|en)/ {print $4}')
  # 网卡的接口名
  INTERFACE=$(ip -o link show | awk -F': ' '$2 ~ /^(eth|en)/ {print $2}')

  cp /etc/netplan/00-installer-config.yaml{,.back}
  cat > /etc/netplan/00-installer-config.yaml <<EOF
  # 参考: https://ubuntuforums.org/showthread.php?t=2491245&p=14159782
  network:
    version: 2
    renderer: networkd
    ethernets:
      lo:
        addresses:
          - 127.0.0.1
      $INTERFACE: # 网卡名称
        dhcp4: false # 是否启用IPV4的DHCP
        dhcp6: false # 是否启用IPV6的DHCP
        addresses: # 网卡的IP地址和子网掩码。例如，192.168.2.152/24 表示IP地址为192.168.2.152，子网掩码为255.255.255.0
          - $ADDRESSES
        nameservers: # 用于指定DNS服务器地址的部分
            # 列出DNS服务器的IP地址
            addresses: [ 223.5.5.5, 223.6.6.6 ]
        routes: # 配置静态路由
            - to: default #目标网络地址，default 表示默认路由, 0.0.0.0/0
              via: $GATEWAY_IP # 指定了路由数据包的下一跳地址，192.168.2.1 表示数据包将通过该地址进行路由
              metric: 100 # 指定了路由的优先级，数值越小优先级越高
              on-link: true # 表示数据包将直接发送到指定的下一跳地址，而不需要经过网关
        mtu: 1500 # 最大传输单元（MTU），表示网络数据包的最大尺寸
EOF
  cat /etc/netplan/00-installer-config.yaml
  # Netplan配置文件不应该对其他用户开放访问权限 过于开放的权限，这可能会导致安全风险
  sudo chmod 600 /etc/netplan/00-installer-config.yaml
  # 生成和应用更改
  sudo netplan generate
  sudo netplan apply
}

# 设置时区
set_timezone () {
  # 设置上海时区
  sudo timedatectl status
  sudo timedatectl set-timezone Asia/Shanghai
}

# TODO
set_hosts () {
  if [[ -e /etc/hosts.back ]];then
    mv /etc/hosts{.back,}
  fi

  # 修改Hosts
  cp /etc/hosts{,.back}
  cat >> /etc/hosts << EOF
192.168.3.100 node-100
192.168.3.101 node-101
192.168.3.102 node-102
192.168.3.103 node-103
EOF
}

set_dns () {
  # systemd-resolved
  # 推荐配置. 会影响CoreDNS, 造成回环问题
  systemctl disable systemd-resolved
  systemctl stop systemd-resolved
  cp /etc/resolv.conf{,.back}
  rm -rf /etc/systemd/resolved.conf
  rm -rf /etc/resolv.conf
  cat > /etc/resolv.conf <<EOF
nameserver 114.114.114.114
EOF
#systemctl status systemd-resolved
}

disable_selinux() {
  echo 关闭SELinux
  sudo setenforce 0 # 临时禁用, 重启变回
  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config # 禁用
}

disable_swap () {
  # SWAP分区
  # kubelet 的默认行为是: 如果在节点上检测到交换内存，则无法启动。自 v1.22 起支持 Swap。
  # 从 v1.28 开始，只有 `cgroup v2` 支持 Swap
  # kubelet 的 NodeSwap 特性门控是 beta 版，但默认处于禁用状态, 允许 kubelet 在节点上使用 swap
  cp /etc/fstab{,.back}
  sed -i '/^\/.*swap/s/^/#/' /etc/fstab
  sudo mount -a
  sudo swapoff -a

  # 检查是否存在swap分区
  if sudo blkid | grep swap -eq 0; then
    echo "swap没有关闭, 建议关闭"
    exit 1
  fi
}

# https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
# 使用kubeadm加入Kubernetes集群时要求net.bridge.bridge-nf-call-iptables=1参数值, 因为Kubernetes默认行为是依赖IPTables这个库
# 如果集群使用了IPv6, 则还需要net.bridge.bridge-nf-call-ip6tables=1这个参数值
# 使用kubeadm创建Kubernetes集群时默认要求net.ipv4.ip_forward = 1
# 如果选择的CNI组件是cilium则不需要下面这些参数
# 在文件名/etc/sysctl.d/99-kubernetes-cri.conf中，`99`代表文件的优先级或顺序。
# sysctl是Linux内核参数的配置工具，它可以通过修改/proc/sys/目录下的文件来设置内核参数。
# 在/etc/sysctl.d/目录中，可以放置一系列的配置文件，以便在系统启动时自动加载这些参数。
# 这些配置文件按照文件名的字母顺序逐个加载。数字前缀用于指定加载的顺序，较小的数字表示较高的优先
# 参数说明:
# net.bridge.bridge-nf-call-iptables  : 启用控制 IPv4 数据包经过桥接时是否要经过 iptables 过滤
# net.bridge.bridge-nf-call-ip6tables : 启用控制 IPv6 数据包经过桥接时是否要经过 ip6tables 过滤
# net.ipv4.ip_forward                 : 启用 IPv4 数据包的转发功能

# 系统优化
set_kernel_parameters () {
  cat > /etc/sysctl.d/99-kubernetes-better.conf <<EOF
net.bridge.bridge-nf-call-iptables        = 1
net.bridge.bridge-nf-call-ip6tables       = 1
net.ipv4.ip_forward                       = 1
vm.swappiness                             = 0
vm.overcommit_memory                      = 0
vm.panic_on_oom                           = 0
fs.inotify.max_user_instances             = 8192
fs.inotify.max_user_watches               = 1048576
fs.file-max                               = 52706963
fs.nr_open                                = 52706963
net.ipv6.conf.all.disable_ipv6            = 1
net.netfilter.nf_conntrack_max            = 25000000
EOF

  modprobe br_netfilter
  lsmod | grep br_netfilter
  # Overlay网络通过在物理网络（即underlay网络）之上构建一个虚拟网络层来实现这一点。
  # 它允许Kubernetes创建一个逻辑网络，其中的Pods可以通过一个统一的网络平面进行通信，而不需要关心底层的物理网络配置
  #modprobe overlay

  modprobe -- nf_conntrack
  lsmod | grep nf_conntrack

  mkdir -p /etc/sysconfig/modules
  cat > /etc/sysconfig/modules/kubernetes.module <<EOF
modprobe br_netfilter
#modprobe overlay
modprobe -- nf_conntrack
EOF
  chmod 755 /etc/sysconfig/modules/kubernetes.module

  # 系统优化
  #cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
#net.bridge.bridge-nf-call-iptables        = 1
#net.bridge.bridge-nf-call-ip6tables       = 1
#net.ipv4.ip_forward                       = 1
#net.ipv4.tcp_slow_start_after_idle        = 0
#net.core.rmem_max                         = 16777216
#kernel.softlockup_all_cpu_backtrace       = 1
#kernel.softlockup_panic                   = 1
#fs.file-max                               = 2097152
#fs.nr_open                                = 2097152
#fs.inotify.max_user_instances             = 8192
#fs.inotify.max_user_watches               = 524288
#fs.inotify.max_queued_events              = 16384
#vm.max_map_count                          = 262144
#net.core.netdev_max_backlog               = 16384
#net.ipv4.tcp_wmem                         = 4096 12582912 16777216
#net.core.wmem_max                         = 16777216
#net.core.somaxconn                        = 32768
#net.ipv4.tcp_timestamps                   = 0
#net.ipv4.tcp_max_syn_backlog              = 8096
#net.bridge.bridge-nf-call-arptables       = 1
#net.ipv4.tcp_rmem                         = 4096 12582912 16777216
#vm.swappiness                             = 0
#kernel.sysrq                              = 1
#net.ipv4.neigh.default.gc_stale_time      = 120
#net.ipv4.conf.all.rp_filter               = 0
#net.ipv4.conf.default.rp_filter           = 0
#net.ipv4.conf.default.arp_announce        = 2
#net.ipv4.conf.lo.arp_announce             = 2
#net.ipv4.conf.all.arp_announce            = 2
#net.ipv4.tcp_max_tw_buckets               = 5000
#net.ipv4.tcp_syncookies                   = 1
#net.ipv4.tcp_synack_retries               = 2
## net.ipv6.conf.lo.disable_ipv6            = 1
#net.ipv6.conf.all.disable_ipv6           = 1
## net.ipv6.conf.default.disable_ipv6       = 1
#net.ipv4.ip_local_port_range              = 1024 65535
#net.ipv4.tcp_keepalive_time               = 600
#net.ipv4.tcp_keepalive_probes             = 10
#net.ipv4.tcp_keepalive_intvl              = 30
#net.nf_conntrack_max                      = 25000000
#net.netfilter.nf_conntrack_max            = 25000000
#net.netfilter.nf_conntrack_tcp_timeout_established = 180
#net.netfilter.nf_conntrack_tcp_timeout_time_wait   = 120
#net.netfilter.nf_conntrack_tcp_timeout_close_wait  = 60
#net.netfilter.nf_conntrack_tcp_timeout_fin_wait    = 12
#EOF

  sysctl --system
}

# 文件限制
set_file_limits () {
  if [ -f /etc/security/limits.conf ];then
    cp /etc/security/limits.conf{,.back}
  fi

  cat >> /etc/security/limits.conf <<EOF
*   soft    nofile  655350
*   hard    nofile  655350
*   soft    nproc   655350
*   hard    nproc   655350
*   soft    core    unlimited
*   hard    core    unlimited
EOF

  cat /etc/security/limits.conf

  if [[ -e /etc/security/limits.d/20-nproc.conf ]];then
    cp /etc/security/limits.d/20-nproc.conf{,.back}
    sed -i "s#4096#655350#g" /etc/security/limits.d/20-nproc.conf
  fi

  if [[ -e /etc/profile.back ]];then
    mv /etc/profile{.back,}
  fi

  cp /etc/profile{,.back}
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

  source /etc/profile
  cat /etc/profile

}

main () {
  "$trace" && set -x
  # 运行前清理
  pre_clear

  apt update -y

  # 验证每个节点的 MAC 地址和product_uuid是否唯一](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address
  sudo cat /sys/class/dmi/id/product_uuid

  # 设置时区
  set_timezone

  set_hosts

  #
  set_dns

  #disable_selinux
  disable_swap
  set_kernel_parameters
  set_file_limits

  cat /etc/security/limits.conf
  cat /etc/profile
  #echo "blkid | grep swap: 为空就正常"
  #sudo blkid | grep swap
}

main "$trace"
