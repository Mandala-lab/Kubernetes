#!/bin/bash

# 删除之前的
rm -rf /etc/crictl.yaml

error_exit() {
    echo "Error: Invalid argument value for $1. Expected 'y' or 'n'."
    exit 1
}
github_proxy=""
install=""
CRICTL_VERSION=""
# 解析命令行参数
while [ "$#" -gt 0 ]; do
    case "$1" in
        --proxy=*)
            value="${1#*=}"  # 提取等号后的值
            if [ "$value" = "y" ]; then
                github_proxy="https://mirror.ghproxy.com/"
            elif [ "$value" = "n" ]; then
                github_proxy=""
            else
                error_exit "$1"
            fi
            shift
            ;;
         --version=*)
            CRICTL_VERSION="${1#*=}"
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

if [ "$CRICTL_VERSION" = "" ]; then
  export CRICTL_VERSION="v1.30.0"
fi

# 如果在环境变量里, 那么跳过下载与安装
if which crictl -eq 0 && $install != "n";then
  echo "crictl已经安装"
  crictl -v
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
    echo "请手动定义你的发行版的架构"
fi

export DOWNLOAD_DIR="/usr/local/bin"
export SAVED_DIR="/tmp"
sudo mkdir -p "$DOWNLOAD_DIR"

# 是否使用github代理
url=""
if [ -n "$github_proxy" ];then
  url="${github_proxy}https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"
  else
    url="https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"
fi

# 如果存在, 那么跳过下载, 直接安装到环境变量, 适用于手动上传
if [ -f "$SAVED_DIR/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" ];then
  tar -zxvf $SAVED_DIR/crictl*.tar.gz -C $DOWNLOAD_DIR
fi

# 无论是否存在, 都重新下载安装
if [ "$install" = "y" ]; then
  wget -t 2 -T 240 -N -S "$url"
  tar -zxvf crictl*.tar.gz -C $DOWNLOAD_DIR
fi

crictl -v
