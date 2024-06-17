#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail -x

declare proxy=false
declare update=true
declare remove=false
declare version="v1.30"

while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy)
      proxy=true
      ;;
    --update)
      update=true
      ;;
    --version=*)
      version="${1#*=}"
      ;;
    --remove)
      remove=true
      ;;
    *)
      echo "未知的命令行选项参数: $1"
      exit 1
      ;;
  esac
  shift
done

remove () {
  # 是否清除旧安装
  if [[ "$remove" == true ]]; then
    systemctl stop kubeadm || true
    systemctl stop kubelet || true
    systemctl stop kubectl || true
    sudo apt purge -y kubeadm kubectl kubelet kubernetes-cni kube* || true
    sudo apt-mark unhold kubeadm || true
    sudo apt-mark unhold kubelet || true
    sudo apt-mark unhold kubectl || true
    sudo apt remove -y kubeadm kubelet kubectl  || true
    rm -rf /usr/local/bin/kube*
    rm -rf /usr/bin/kube*
    rm -rf /var/lib/kube*
    rm -rf /etc/sysconfig/kubelet
    rm -rf /etc/kubernetes
    rm -rf /etc/apt/sources.list.d/kubernetes.list
    rm -rf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
    sudo apt autoremove -y
  fi
}

unset_var () {
  unset http_proxy
  unset https_proxy
}

install_base_pack () {
  # 安装基础工具
  sudo apt install -y apt-transport-https ca-certificates curl conntrack socat
}

add_k8s_repo () {
  # 配置kubernetes 源按照安装版本区分不同仓库: https://developer.aliyun.com/mirror/kubernetes
  if [ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ];then
      rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  fi
  if [[ "$proxy" == false ]];then
    # 服务器可以访问pkgs.k8s.io时使用官方镜像:
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$version/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list
    mkdir -p /etc/apt/keyrings/
    curl -fsSL https://pkgs.k8s.io/core:/stable:/"$version"/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    else
    ## 国内代理:
    if [ -f /etc/apt/sources.list.d/kubernetes.list ];then
      rm -rf /etc/apt/sources.list.d/kubernetes.list
    fi
    curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/"$version"/deb/Release.key |
        gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/$version/deb/ /" |
        tee /etc/apt/sources.list.d/kubernetes.list
  fi
}

install_k8s_comm () {
  # 遇到
  # Reading package lists... Done
  # E: Method https has died unexpectedly!
  # E: Sub-process https received signal 4.
  # GNUTLS_CPUID_OVERRIDE=0x1 apt update -y
  if [[ "$update" == true ]];then
    apt update -y
  fi
  # GNUTLS_CPUID_OVERRIDE=0x1 apt install -y conntrack socat kubelet kubeadm
  apt install -y kubelet kubeadm
}

# 配置 cgroup 驱动与CRI一致
config_cgroup_kubelet() {
  if [ -f /etc/sysconfig/kubelet ];then
    cp /etc/sysconfig/kubelet{,.back}
  fi
  mkdir -p /etc/sysconfig
  cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF
}

verify () {
  cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
  cat /etc/sysconfig/kubelet
  # 清理旧的安装信息
  which kubeadm kubelet
  hash -r
  systemctl daemon-reload

  systemctl enable --now kubelet
  #systemctl status kubelet

  # 注意：如果 ipvs 模式成功打开，您应该会看到 IPVS 代理规则（使用 ipvsadm ），例如
  # ipvsadm -ln
  # IP Virtual Server version 1.2.1 (size=4096)
  # Prot LocalAddress:Port Scheduler Flags
  #   -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
  # TCP  10.0.0.1:443 rr persistent 10800
  #   -> 192.168.0.1:6443             Masq    1      1          0

  # 或类似的日志出现在 kube-proxy 日志中（例如， /tmp/kube-proxy.log 对于本地集群），当本地集群正在运行时：
  # Using ipvs Proxier.
  # While there is no IPVS proxy rules or the following logs occurs indicate that the kube-proxy fails to use IPVS mode:
  # 虽然没有 IPVS 代理规则或出现以下日志，但表明 kube-proxy 无法使用 IPVS 模式：
  # Can't use ipvs proxier, trying iptables proxier
  # Using iptables Proxier.
  kubeadm version
  kubelet --version
}

main () {
  remove
  unset_var
  install_base_pack
  add_k8s_repo "$proxy"
  install_k8s_comm "$update"
  config_cgroup_kubelet
  verify
}

main "$@"
