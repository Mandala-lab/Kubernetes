#!/bin/bash

# 删除之前的
rm -rf /etc/crictl.yaml

declare github_proxy=false
declare github_proxy_url=""
declare install=false
declare version="v1.32.0"
declare url=""
declare SAVED_DIR="/tmp"
declare DOWNLOAD_DIR="/usr/local/bin"

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

# 如果在环境变量里, 那么跳过下载与安装
is_install () {
   echo "install: $install"
   if which crictl && [[ "$install" == false ]];then
     echo "crictl 已经安装"
     crictl -v
     exit 0
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

# 是否使用github代理
set_url () {
  if [[ -z $url ]];then
   echo "set default url"
   url="https://github.com/kubernetes-sigs/cri-tools/releases/download/${version}/crictl-${version}-linux-${ARCH}.tar.gz"
  fi

  echo "github_proxy_url: $github_proxy_url"
  echo "url: $url"

  if [[ -n "$github_proxy" && "$url" ]];then
   echo "set proxy url"
   url="${github_proxy_url}${url}"
  fi
}

download () {
   wget -t 2 -T 240 -N -S "$url"
   tar -zxvf crictl*.tar.gz -C $DOWNLOAD_DIR
}

install_crictl () {
  sudo mkdir -p "$SAVED_DIR"
  cd "$SAVED_DIR" || exit

  # 无论是否存在, 都重新下载安装
  if [[ "$install" == true ]]; then
    download
    # 如果存在, 那么跳过下载, 直接安装到环境变量, 适用于手动上传
    elif [ -f "$SAVED_DIR/crictl-${version}-linux-${ARCH}.tar.gz" ];then
       tar -zxvf $SAVED_DIR/crictl*.tar.gz -C $DOWNLOAD_DIR
    else
      download
  fi
}

verify () {
  which crictl
  crictl -v
}

main () {
  is_install
  set_arch
  set_url "$url"
  install_crictl "$install" "$url"
  verify
}

main
