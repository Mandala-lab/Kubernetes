#!/bin/bash

set -e -o posix -o pipefail -x

declare github_proxy=false
declare github_proxy_url=""
declare install=false
declare version="v1.1.12"
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
   url="https://github.com/opencontainers/runc/releases/download/${version}/runc.${ARCH}"
  fi

  echo "github_proxy_url: $github_proxy_url"
  echo "url: $url"

  if [[ -n "$github_proxy" && "$url" ]];then
   echo "set proxy url"
   url="${github_proxy_url}${url}"
  fi
}

is_install () {
   echo "install: $install"
   if which runc && [[ "$install" == false ]];then
     echo "runc已经安装"
     runc -v
     exit 0
   fi
}

install_runc () {
  # runc 是操作系统级别的软件包 用于与Containerd Docker Podman等CRI底层的OCI工具
  # Containerd -> runc
  # 少数情况下, 系统可能没有安装runc或者配置不正确

  is_install "$install"

  wget -t 2 -T 240 -N -S "$url"
  install -m 755 ./runc."${ARCH}" /usr/local/sbin/runc
  rm -rf ./runc.${ARCH}
}

echo "url:$url"

verify () {
  which runc
  runc -v
}

main () {
  set_arch
  set_url "$url"
  install_runc "$url" "$ARCH" "$version" "$install"
  verify
}

main "$@"
