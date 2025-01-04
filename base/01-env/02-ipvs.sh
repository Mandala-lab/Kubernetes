#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o pipefail -x

# 定义确认函数
confirm_execution() {
    local timeout=5
    local default="y"
    local response

    echo "是否继续执行？ (y/n，默认 $default，5秒后自动继续)"

    # 使用 read -t 来设置超时时间
    read -r -p "[y/N] " -t "$timeout" response

    # 如果用户没有输入任何内容，默认选择 y
    if [ -z "$response" ]; then
        response="$default"
    fi

    # 将用户输入转换为小写
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    # 检查用户输入是否为 n
    if [ "$response" = "n" ]; then
        echo "用户选择不执行。退出脚本。"
        exit 0
    fi

    echo "继续执行..."
}

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
  ipset
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
  # 在执行主逻辑之前，调用 confirm_execution 函数进行确认
  confirm_execution

  pre_clear
  install_pack
  load_param
  cat /etc/sysconfig/modules/ipvs.modules

  # 使用命令查看是否已经正确加载所需的内核模块:
  lsmod | grep -e ip_vs -e nf_conntrack
  cut -f1 -d " "  /proc/modules | grep -e ip_vs -e nf_conntrack
}

main "$trace"
