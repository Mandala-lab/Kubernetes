#!/bin/bash
# 此文件是用于下载二进制的Containerd
# 并针对国内服务器进行优化
# 添加镜像拉取的源替换为国内的镜像源

set -o posix -o errexit -o pipefail

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

github_proxy=""
install=""
VERSION=""
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
                github_proxy="https://mirror.ghproxy.com/"
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
        --version=*)
            VERSION="${1#*=}"
            shift
            ;;
        *)  # 处理未知选项
            echo "Error: Unsupported argument $1."
            exit 1
            ;;
    esac
done

# 安装containerd
# TODO 编写可动态获取版本的shell
if [ "$VERSION" = "" ];then
  VERSION="1.7.17"
fi

if which ctr -eq 0 && $install != "n";then
  echo "containerd已经安装"
  ctr -v
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

echo "ARCH=${ARCH}"

url=""
if [ -n "$github_proxy" ];then
  url="${github_proxy}https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-${ARCH}.tar.gz"
  else
    url="https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-${ARCH}.tar.gz"
fi

function download() {
    wget -t 2 -T 240 -N -S "$url"
    tar -zxvf containerd-"$VERSION"-linux-$ARCH.tar.gz -C /usr/local/
}

# 定义containerd的保存路径, 用于保存下载的Containerd二进制文件
CONTAINERD_HOME="/home/containerd"
mkdir -p $CONTAINERD_HOME
cd $CONTAINERD_HOME || exit
if [ -f "containerd-$VERSION-linux-$ARCH.tar.gz" ]; then
    echo "文件存在"
    if tar -zxvf containerd-"$VERSION"-linux-$ARCH.tar.gz -C /usr/local/ -eq 2; then
      echo "文件已损坏, 正在重新下载"
      rm -rf containerd-"$VERSION"-linux-$ARCH.tar.gz
      download
    fi
else
    echo "文件不存在"
    download
fi
