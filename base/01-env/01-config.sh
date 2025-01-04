#!/usr/bin/env bash
#
# 配置Kubernetes所需要的基本依赖项, 例如内核参数, 启用和使用社区广泛推荐的内核参数

set -e -o posix -o pipefail -x

declare resolve_dns=1.1.1.1
while [ "$#" -gt 0 ]; do
    case "$1" in
        --trace=*)
            trace=true
            shift
            ;;
        --resolve_dns=*)
            resolve_dns="${1#*=}"
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

# TODO 设置静态路由
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

set_timezone () {
  echo "设置时区"
  echo "设置上海时区"
  sudo timedatectl status
  sudo timedatectl set-timezone Asia/Shanghai
}

#set_time() {
#  echo "使用ntpdate命令同步时间"
##  sudo apt install ntpdate
##  sudo ntpdate time1.aliyun.com
#
#  echo "在安装 ntpd 之前，需要关闭 timesyncd，以防止这两个服务之间的相互冲突。"
#  sudo timedatectl set-ntp no
#  sudo apt update -y
#  sudo apt install ntp -y
#}

# TODO set_hosts
set_hosts () {
  if [[ -e /etc/hosts.back ]];then
    mv /etc/hosts{.back,}
  fi

  # 修改Hosts
  cp /etc/hosts{,.back}
  cat > /etc/hosts << EOF
127.0.1.1 localhost.localdomain VM-20-8-ubuntu
127.0.0.1 localhost

::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

EOF
cat /etc/hosts
}

# TODO set_dns
set_dns () {
  # systemd-resolved
  echo "正在配置systemd-resolved. 错误的设置会影响CoreDNS, 造成回环问题"
  systemctl disable systemd-resolved
  systemctl stop systemd-resolved
  cp /etc/resolv.conf{,.back}
  rm -rf /etc/systemd/resolved.conf
  rm -rf /etc/resolv.conf
  cat > /etc/resolv.conf <<EOF
nameserver $resolve_dns
EOF
#systemctl status systemd-resolved
}

disable_selinux() {
  echo "关闭SELinux"
  if command -v setenforce >/dev/null 2>&1; then
      echo "setenforce 命令存在，正在执行 setenforce 0 以临时禁用 SELinux"
      sudo setenforce 0
    else
      echo "setenforce 命令不存在，跳过此步骤"
  fi
  if [[ -d /etc/selinux && -e /etc/selinux/config  ]]; then
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config # 禁用
  fi
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
    echo "swap没有关闭, 请关闭"
    exit 1
  fi

  if sudo blkid | grep swap; then
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

set_kernel_parameters () {

  # Overlay网络通过在物理网络（即underlay网络）之上构建一个虚拟网络层来实现这一点。
  # 它允许Kubernetes创建一个逻辑网络，其中的Pods可以通过一个统一的网络平面进行通信，而不需要关心底层的物理网络配置
  sudo modprobe nf_conntrack
  sudo modprobe br_netfilter
  sudo lsmod | grep br_netfilter
  modprobe overlay
  lsmod | grep br_netfilter

  echo "通过运行以下指令确认 net.bridge.bridge-nf-call-iptables、net.bridge.bridge-nf-call-ip6tables 和 net.ipv4.ip_forward 系统变量在你的 sysctl 配置中被设置为 1"
  sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward vm.swappiness vm.overcommit_memory vm.panic_on_oom fs.inotify.max_user_instances fs.inotify.max_user_watches fs.file-max fs.nr_open net.ipv6.conf.all.disable_ipv6 net.netfilter.nf_conntrack_max

  sysctl --system
}

set_file_limits () {
  echo "设置文件限制"
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

  echo "正在设置推荐的内核参数"
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

  mkdir -p /etc/modules-load.d
  cat << EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
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


# TODO: 改为更安全的方式
set_ufw() {
  # 检查 ufw 命令是否存在
  if command -v ufw &> /dev/null; then
      echo "不安全的方式, 正在关闭防火墙"
      sudo ufw disable
      sudo ufw status
  else
      echo "ufw 未安装，正在安装..."
      sudo apt update
      sudo apt install -y ufw
      echo "ufw 安装完成"

      # 检查安装是否成功
      if command -v ufw &> /dev/null; then
          echo "不安全的方式, 正在关闭防火墙"
          sudo ufw disable
          sudo ufw status
      else
          echo "ufw 安装失败"
      fi
  fi
}


main () {
  "$trace" && set -x
  # 运行前清理
  pre_clear

  # 验证每个节点的 MAC 地址和product_uuid是否唯一](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address
  sudo cat /sys/class/dmi/id/product_uuid

  # set_static_route

  # 设置时区
  set_timezone

  #  set_hosts

  set_dns
  disable_selinux
  disable_swap
  set_kernel_parameters
  set_file_limits
  set_ufw

  cat /etc/security/limits.conf
  cat /etc/profile
  #echo "blkid | grep swap: 为空就正常"
  #sudo blkid | grep swap
}

main "$trace"
