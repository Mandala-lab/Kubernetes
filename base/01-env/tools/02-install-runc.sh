#!/bin/bash

set -e -o posix -o pipefail -x

unset github_proxy
unset install
unset version
unset url

declare github_proxy=false
declare github_proxy_url=""
declare install=false
declare version="1.2.4"
declare url=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy)
      github_proxy=true
      github_proxy_url="https://www.ghproxy.cn/"
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
   url="https://github.com/opencontainers/runc/releases/download/$v${version}/runc.${ARCH}"
  fi

  echo "github_proxy_url: $github_proxy_url"
  echo "url: $url"

  if [[ -n "$github_proxy" && "$url" ]];then
   echo "set proxy url"
   url="${github_proxy_url}${url}"
  fi
}

install_runc () {
  # runc 是操作系统级别的软件包 用于与Containerd Docker Podman等CRI底层的OCI工具
  # Containerd -> runc
  # 少数情况下, 系统可能没有安装runc或者配置不正确

  wget -t 2 -T 240 -N -S "$url"
  install -m 755 ./runc."${ARCH}" /usr/local/sbin/runc
  rm -rf ./runc.${ARCH}
}

echo "url:$url"

verify () {
  which runc
  runc -v
}

check_local() {
  echo "正在检查 /tmp 目录中是否存在 runc.${ARCH} 二进制文件"
  if ls /tmp/runc.${ARCH} 1> /dev/null 2>&1; then
    echo "找到 runc.${ARCH} 二进制文件，开始安装..."

    # 安装 runc 到 /usr/local/sbin/
    install -m 755 /tmp/runc.${ARCH} /usr/local/sbin/runc

    # 删除下载的二进制文件
    rm -rf /tmp/runc.${ARCH}

    echo "runc 已成功更新到版本 $version"
  else
    echo "未找到 runc.${ARCH} 二进制文件，请确保文件已下载到 /tmp 目录。即将进行网络下载"
    echo "下载runc二进制文件"
    set_url "$url"
    install_runc "$url" "$ARCH" "$version" "$install"
    verify
  fi
}

check_runc() {
  # 使用 which 检查 runc 是否已安装
  if ! which runc > /dev/null 2>&1; then
    echo "runc 未安装，检查本地是否有新版进行安装..."
    check_local
    return 0 # 未安装时直接退出函数
  fi

  # 获取 runc 的版本信息
  local_version=$(runc -v 2>&1 | grep -oP 'runc version \K[0-9]+\.[0-9]+\.[0-9]+')

  # 检查是否成功获取版本号
  if [ -z "$local_version" ]; then
    echo "无法获取 runc 的版本号。"
    exit 1
  fi

  # 输出版本号
  echo "本地 runc 版本: $local_version"
  echo "期望版本: $version"

  # 使用 sort -V 进行版本号比较
  if [ "$(printf "%s\n" "$local_version" "$version" | sort -V | head -n1)" = "$local_version" ]; then
    echo "本地版本号小于期望版本号, 判断本地是否存在新版"
    check_local
  else
    echo "本地版本号大于期望版本号"
  fi
}

main () {
  set_arch
  check_runc
}

main "$@"
