#!/bin/bash
set -e -o posix -o pipefail

declare github_proxy=false
declare github_proxy_url=""
declare version="v1.6.2"

while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy)
      github_proxy=true
      github_proxy_url="https://www.ghproxy.cn/"
      ;;
    --github_proxy_url=*)
      github_proxy_url="${1#*=}"
      ;;
    --version=*)
      version="${1#*=}"
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
echo $ARCH

if [[ -z $url ]];then
 echo "set default url"
 file_url="https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-${ARCH}-${version}.tgz"
 sha256_url="https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-${ARCH}-${version}.tgz.sha256"
fi

echo "github_proxy_url: $github_proxy_url"
declare url=""
if [[ -n "$github_proxy" ]];then
 echo "set proxy url"
 url="${github_proxy_url}${file_url}"
 sha256_url="${github_proxy_url}${sha256_url}"
fi

# 跟随重定向, 状态码为400就失败, 设置超时300秒, 使用远程文件的名称
echo "url: ${url}"
echo "file_url: ${file_url}"
echo "sha256_url: ${sha256_url}"

rm -rf cni-plugins-linux-${ARCH}-${version}.tgz
rm -rf cni-plugins-linux-${ARCH}-${version}.tgz.sha256

wget "${url}"
wget "${sha256_url}"

# 校验文件是否完整
sha256sum -c cni-plugins-linux-${ARCH}-${version}.tgz.sha256

mkdir -p /opt/cni/bin
tar -xzvf cni-plugins-linux-${ARCH}-${version}.tgz -C /opt/cni/bin

set +x
