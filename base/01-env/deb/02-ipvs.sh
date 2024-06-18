#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail -x

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

# 删除旧配置
pre_clear () {
  if [ -f /etc/sysconfig/modules/ipvs.modules ];then
      rm -f /etc/sysconfig/modules/ipvs.modules
  fi
}

# 下载基本的依赖包
install_pack () {
  # conntrack: 用于追踪和管理网络连接状态，特别对于NAT（网络地址转换）和防火墙规则非常有用。
  # ipvsadm: 是一个用于管理和配置Linux内核中的IP Virtual Server (IPVS)模块的工具，该模块用于实现负载均衡。
  # ipset: 提供了一个高效的数据结构来存储和查询IP地址，常用于构建复杂的防火墙规则。
  # jq: 是一个轻量级且灵活的命令行JSON处理器，用于解析、过滤和修改JSON格式的数据。
  # iptables: 用于设置、维护和检查Linux内核的IP表，实现包过滤和网络地址转换等功能。
  # curl: 是一个用于从或向服务器传输数据的强大工具，支持多种协议如HTTP, HTTPS, FTP等。
  # sysstat: 包含一系列用于系统性能监控的工具，如sar, iostat, mpstat等，可以收集和报告系统的各种统计信息。
  # wget: 一个非交互式的网络文件下载工具，可以从网页上下载文件，支持断点续传。
  # net-tools: 包含了一系列用于网络诊断和管理的工具，如ifconfig, netstat等。
  # git: 是一个分布式版本控制系统，用于跟踪在软件开发过程中的文件变化，以便于回溯历史版本和协作开发。
  apt install -y \
  conntrack \
  ipvsadm \
  ipset \
  wget \
  git
}

# 加载内核参数
load_param () {
  mkdir -pv /etc/sysconfig/modules
  touch /etc/sysconfig/modules/ipvs.modules
  chmod +x /etc/sysconfig/modules/ipvs.modules

  cat > ipvs.sh <<EOF
ipvs_mods_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
for i in \$(ls \$ipvs_mods_dir|grep -o "^[^.]*" )
do
  /sbin/modinfo -F filename \$i &>/dev/null
  if [ \$? -eq 0 ];then
        /sbin/modprobe \$i
        echo "/sbin/modprobe \$i" >> /etc/sysconfig/modules/ipvs.modules
  fi
done
EOF

  source ./ipvs.sh
}

main () {
  pre_clear
  install_pack

  cat /etc/sysconfig/modules/ipvs.modules

  # 使用命令查看是否已经正确加载所需的内核模块:
  lsmod | grep -e ip_vs -e nf_conntrack
  cut -f1 -d " "  /proc/modules | grep -e ip_vs -e nf_conntrack
}

main "$trace"
