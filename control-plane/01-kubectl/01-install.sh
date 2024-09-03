#!/bin/bash

set -e -o posix -o pipefail

declare DOWNLOAD_HOME="/home/kubernetes"
declare RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
#declare RELEASE="v1.30.2"
declare ARCH="amd64"
declare DOWNLOAD_DIR="/usr/local/bin"

mkdir -p $DOWNLOAD_HOME
cd "$DOWNLOAD_HOME" || exit

while [[ $# -gt 0 ]]; do
  case $1 in
    --DOWNLOAD_HOME=*)
      DOWNLOAD_HOME="${1#*=}"
      ;;
    --RELEASE=*)
      RELEASE="${1#*=}"
      ;;
    --ARCH=*)
      ARCH="${1#*=}"
      ;;
    --DOWNLOAD_DIR=*)
      DOWNLOAD_DIR="${1#*=}"
      ;;
    *)
      echo "未知的命令行选项参数: $1"
      exit 1
      ;;
  esac
  shift
done

# 输出最终的架构名称
echo "Detected architecture: $ARCH"

# kubectl
if [ -f "$DOWNLOAD_HOME/kubectl" ] && [ -f "$DOWNLOAD_HOME/kubectl.sha256" ]; then
    if echo "$(cat kubectl.sha256) kubectl" | sha256sum -c; then
      echo "kubectl 的SHA256 校验成功"
    else
      echo "kubectl 的SHA256 校验失败，退出并报错"
      rm -rf kubectl kubectl.sha256
      exit 1
    fi

    rm -rf $DOWNLOAD_DIR/kubectl
    sudo install -o root -g root -m 0755 kubectl $DOWNLOAD_DIR/kubectl
else
    echo "kubectl.service 不存在"
    #sudo curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubectl,kubectl.sha256}"
    sudo wget -t 2 -T 240 -N -S https://dl.k8s.io/release/"${RELEASE}"/bin/linux/${ARCH}/{kubectl,kubectl.sha256}
    if echo "$(cat kubectl.sha256) kubectl" | sha256sum -c; then
      echo "kubectl 的SHA256 校验成功"
    else
      echo "kubectl 的SHA256 校验失败，退出并报错"
      rm -rf kubectl kubectl.sha256
      exit 1
    fi

    sudo install -o root -g root -m 0755 kubectl $DOWNLOAD_DIR/kubectl
fi

# 查看版本的详细视图
# kubectl version --client --output=yaml
