#!/bin/bash
# 此文件是用于下载二进制的Containerd
# 并针对国内服务器进行优化
# 添加镜像拉取的源替换为国内的镜像源

set -e -o posix -o pipefail -x

declare github_proxy=false
declare github_proxy_url=""
declare install=false
declare version="1.7.17"
declare url=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy)
      github_proxy=true
      github_proxy_url="https://mirror.ghproxy.com/"
      ;;
    --proxy_url=*)
      github_proxy_url="${1#*=}"
      ;;
    --install)
      install=true
      ;;
    --version=*)
      version="${1#*=}"
      ;;
    --url=*)
      url="${1#*=}"
      ;;
    *)
      echo "未知的命令行选项参数: $1"
      exit 1
      ;;
  esac
  shift
done
# 返回解析后的参数值
echo "proxy:$github_proxy install:$install version:$version"

pre_clear () {
  unset "$CONTAINERD_HOME"

  # 设置containerd.service的默认路径
  if [ -z "${CONTAINERD_SERVICE}" ]; then
    export CONTAINERD_SERVICE="/etc/systemd/system/containerd.service"
  fi
  # 设置containerd配置文件config.toml的路径
  if [ -z "${CONTAINERD_CONFIG_FILE_PATH}" ]; then
    export CONTAINERD_CONFIG_FILE_PATH="/etc/containerd/config.toml"
  fi

  # 删除之前的
  rm -rf /opt/containerd/
  rm -rf /usr/bin/ctr
  rm -rf /etc/containerd/
  rm -rf $CONTAINERD_SERVICE
  rm -rf $CONTAINERD_CONFIG_FILE_PATH
  rm -rf /etc/modules-load.d/containerd.conf
  rm -rf /etc/sysctl.d/99-kubernetes-cri.conf

  hash -r
}

# 函数：显示错误消息并退出
errorExit() {
    echo "Error: Invalid argument value for $1. Expected 'y' or 'n'."
    exit 1
}

download() {
    wget -t 2 -T 240 -N -S "$url"
    tar -zxvf containerd-"$version"-linux-"$ARCH".tar.gz -C /usr/local/
}

is_install () {
   echo "install: $install"
   if which ctr && [[ "$install" == false ]];then
     echo "containerd已经安装"
     ctr -v
     exit 0
   fi
}

install_containerd() {
  # 安装containerd
  is_install "$install"

  # 定义containerd的保存路径, 用于保存下载的Containerd二进制文件
  CONTAINERD_HOME="/home/containerd"
  mkdir -p $CONTAINERD_HOME
  cd $CONTAINERD_HOME || exit
  if [ -f "containerd-$version-linux-$ARCH.tar.gz" ]; then
      echo "文件存在"
      if ! tar -zxvf containerd-"$version"-linux-$ARCH.tar.gz -C /usr/local/; then
        echo "文件已损坏, 正在重新下载"
        rm -rf containerd-"$version"-linux-$ARCH.tar.gz
        download "$url"
      fi
  else
      echo "文件不存在"
      download "$url"
  fi

}

set_arch() {
  ARCH=""
  # 使用uname -m获取架构信息
  machine=$(uname -m)
  # 判断架构信息并设置变量的值
  if [ "$machine" = "aarch64" ]; then
      ARCH="arm64"
  elif [ "$machine" = "x86_64" ]; then
      ARCH="amd64"
  else
      echo "请手动定义你的发行版的架构"
  fi

  echo "ARCH=${ARCH}"
}

set_url () {
  if [[ -z $url ]];then
   echo "set default url"
   url="https://github.com/containerd/containerd/releases/download/v${version}/containerd-${version}-linux-${ARCH}.tar.gz"
  fi

  echo "github_proxy_url: $github_proxy_url"
  echo "url: $url"

  if [[ -n "$github_proxy" && "$url" ]];then
   echo "set proxy url"
   url="${github_proxy_url}${url}"
  fi
}

main() {
  pre_clear
  set_arch
  set_url "$url"
  install_containerd "$install" "$ARCH" "$url"
}

main "$@"
