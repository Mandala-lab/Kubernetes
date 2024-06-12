#!/bin/bash

set -o posix -o errexit -o pipefail -x

github_proxy=""
install=""
# 函数：显示错误消息并退出
error_exit() {
    echo "Error: Invalid argument value for $1. Expected 'y' or 'n'."
    exit 1
}

# 解析命令行参数
while [ "$#" -gt 0 ]; do
    case "$1" in
        --proxy=*)
            value="${1#*=}"  # 提取等号后的值
            if [ "$value" = "y" ]; then
                github_proxy="https://mirrors.chenby.cn/"
            elif [ "$value" = "n" ]; then
                github_proxy=""
            else
                error_exit "$1"
            fi
            shift
            ;;
        --install=*)
            value="${1#*=}"
            if [ "$value" = "y" ] || [ "$value" = "n" ]; then
                install="$value"
            else
                error_exit "$1"
            fi
            shift
            ;;
        *)  # 处理未知选项
            echo "Error: Unsupported argument $1."
            exit 1
            ;;
    esac
done

# runc 是操作系统级别的软件包 用于与Containerd Docker Podman等CRI底层的OCI工具
# Containerd -> runc
# 少数情况下, 系统可能没有安装runc或者配置不正确
# TODO 切换为动态获取
VERSION="v1.1.12"

if which runc -eq 0 && $install != "n";then
  echo "runc已经安装"
  runc -v
  exit 0
fi

ARCH=""
# 使用uname -m获取架构信息
machine=$(uname -m)
# 判断架构信息并设置变量的值
if [ "$machine" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$machine" = "x86_64" ]; then
    ARCH="amd64"
else
    echo "无法失败当前操作系统的架构, 请手动定义你的发行版的架构: ARCH=你的操作系统架构, 例如: ARCH=\"amd64\" "
    exit 1
fi
echo $ARCH

url=""
if [ -n "$github_proxy" ];then
  url="${github_proxy}https://github.com/opencontainers/runc/releases/download/${VERSION}/runc.${ARCH}"
  else
    url="https://github.com/opencontainers/runc/releases/download/${VERSION}/runc.${ARCH}"
fi

wget -t 2 -T 240 -N -S $url
install -m 755 ./runc.${ARCH} /usr/local/sbin/runc

rm -rf ./runc.${ARCH}

echo "url:$url"

runc -v

