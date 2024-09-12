#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail -x

set_base_env() {
  echo "基础环境设置"
  # TODO 默认关闭ufw防火墙
  chmod +x ./base/01-env/deb/01-config.sh
  ./base/01-env/deb/01-config.sh
}

set_ipvs() {
  echo "set IPVS"
  chmod +x ./base/01-env/deb/02-ipvs.sh
  ./base/01-env/deb/02-ipvs.sh
}

set_kubernetes_port() {
  echo "放行kubernetes所需的端口"
  chmod +x ./base/01-env/deb/03-allow-port.sh
  ./base/01-env/deb/03-allow-port.sh
}

install_containerd() {
  # TODO: 切换成apt安装的ctr
  echo "安装containerd"
  # --proxy: 使用国内github代理
  # --github_proxy_url: 如果使用了--proxy 国内的github的代理, 请填写此项, 否则请删除该项或者填值位空字符串
  # --install: 覆盖安装, 无论是否已经安装了containerd
  # --version: containerd的版本, 从 https://github.com/containerd/containerd/releases 查找版本
  chmod +x ./base/02-cri/containerd/binarymode/01-install.sh
  # 下载前检查containerd是否已经存在于环境变量, 如果存在则不下载
  #./base/02-cri/containerd/binarymode/01-install.sh --proxy --install=n --version="1.7.21"
  # 不使用任何代理, 适用于可以直接访问github的服务器
  ./base/02-cri/containerd/binarymode/01-install.sh --github_proxy_url="" --install --version="1.7.21"
  # 使用国内github代理
  #./base/02-cri/containerd/binarymode/01-install.sh --proxy --github_proxy_url="https://mirror.ghproxy.com/" --install --version="1.7.21"
}

config_containerd() {
  # 配置containerd参数
  # --proxy: 使用国内github代理
  # --github_proxy_url: 如果使用了--proxy 国内的github的代理, 请填写此项, 否则请删除该项或者填值位空字符串
  # --sandbox_image_url: k8s组件的镜像url, 默认值为 registry.k8s.io/pause:3.10
  chmod +x ./base/02-cri/containerd/binarymode/02-config.sh
  # 原版镜像
  ./base/02-cri/containerd/binarymode/02-config.sh
}

install_runc() {
  echo "安装runc"
  chmod +x ./base/02-cri/containerd/apt/03-install-runc.sh
  ./base/02-cri/containerd/apt/03-install-runc.sh
}

install_crictl() {
  echo "安装crictl"
  echo "如果需要手动上传, 那么请上传二进制文件到/tmp, 文件名为: crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"
  # CRICTL_VERSION: 版本, 例如v1.30.0
  # ARCH: 架构, 例如, amd64
  chmod +x ./base/03-components/01-crictl/01-install.sh
  #./base/03-components/01-crictl/01-install.sh --proxy=y --install --version="v1.31.1"
  ./base/03-components/01-crictl/01-install.sh --install --version="v1.31.1"
}

install_kubernetes_components() {
  chmod +x ./base/03-components/02-comm/deb/01-install-kubernetes-components.sh
  ./base/03-components/02-comm/deb/01-install-kubernetes-components.sh
}

main() {
  set_base_env
  set_ipvs
  set_kubernetes_port
  install_containerd
  config_containerd
  install_runc
  install_crictl
  install_kubernetes_components
}

main
