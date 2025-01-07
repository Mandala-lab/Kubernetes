#!/bin/bash
# 此文件是用于下载二进制的Containerd
# 并针对国内服务器进行优化
# 添加镜像拉取的源替换为国内的镜像源

set -e -o posix -o pipefail -x

declare github_proxy=false
declare github_proxy_url=""
declare url=""
declare sandbox_image_url="registry.k8s.io/pause:3.10"

while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy)
      github_proxy=true
      github_proxy_url="https://www.ghproxy.cn/"
      ;;
    --proxy_url=*)
      github_proxy_url="${1#*=}"
      ;;
    --sandbox_image_url=*)
      sandbox_image_url="${1#*=}"
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

set_containerd_path() {
  # 设置containerd.service的默认路径
  if [ -z "${CONTAINERD_SERVICE}" ]; then
    export CONTAINERD_SERVICE="/etc/systemd/system/containerd.service"
  fi
  # 设置containerd配置文件config.toml的路径
  if [ -z "${CONTAINERD_CONFIG_FILE_PATH}" ]; then
    export CONTAINERD_CONFIG_FILE_PATH="/etc/containerd/config.toml"
  fi

  echo "正在生成containerd的文件"
  # 生成containerd的配置文件
  mkdir -p /etc/containerd/
  containerd config default | tee "$CONTAINERD_CONFIG_FILE_PATH"
  # 配置文件默认在`/etc/containerd/config.toml` 这里仅修改两处配置
  # 替换为国内镜像, 国内服务器可以使用k8s.m.daocloud.io或者registry.cn-hangzhou.aliyuncs.com/google_containers/pause
  #  sed -i 's#sandbox = .*#sandbox = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10"#' "$CONTAINERD_CONFIG_FILE_PATH"
  sed -i "s#sandbox = .*#sandbox = \"$sandbox_image_url\"#" "$CONTAINERD_CONFIG_FILE_PATH"
  grep -nE "sandbox" "$CONTAINERD_CONFIG_FILE_PATH"

  # 当 systemd 是选定的初始化系统时, 应当选择SystemdCgroup = true, 否则不需要修改
  # 要在runc中使用 systemd的cgroup 驱动程序，请将 /etc/containerd/config.toml修改SystemdCgroup为true
  # 如果使用 cgroup v2，建议使用 systemd的cgroup 驱动程序
  # 参考: https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/#containerd-systemd
  # 2.x版本以上已删除, 旧版本使用: sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' "$CONTAINERD_CONFIG_FILE_PATH"
  sed -i "/ShimCgroup = ''/a \            SystemdCgroup = true" "$CONTAINERD_CONFIG_FILE_PATH"

  # 下载containerd.service
  # 配置containerd的service单元文件
  # 命令说明:
  # 1. 如果存在containerd.service,内容 可能不是最新的, 而且也会影响下载下来的文件名
  # 删除当前目录的containerd.service, 如果文件不存在, rm -rf 也不会删除, 无需判断文件是否存在
  # 2. 从Github的containerd下载containerd.service文件, 如果下载失败, 则使用内置的文件进行替换
  # 删除旧的containerd.service文件
  rm -rf ./containerd.service
}

set_url () {
  if [[ -z $url ]];then
   echo "set default url"
   url="https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"
  fi

  echo "github_proxy_url: $github_proxy_url"
  echo "url: $url"

  if [[ -n "$github_proxy" && "$url" ]];then
   echo "set proxy url"
   url="${github_proxy_url}${url}"
  fi
}

# 尝试从GitHub下载containerd.service文件，超时时间为10秒
download_ctr_service () {
  if ! wget -t 2 -T 30 -N -S "$url"; then
    echo "下载containerd.service失败, 正在使用内置的文件进行替换, 但可能不是最新的, 可以进行手动替换"
    cat > "$CONTAINERD_SERVICE" << EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
  else
    # 如果下载成功，使用sudo命令将containerd.service内容写入CONTAINERD_SERVICE文件
    sudo cat containerd.service | sudo tee "$CONTAINERD_SERVICE"
  fi
}

# 所有节点均需安装与配置, 根据实际需求, 推荐Kubernetes安装v1.24版本以上使用containerd. 本教程只使用containerd
# 创建/etc/modules-load.d/containerd.conf配置文件，确保在系统启动时自动加载所需的内核模块，以满足容器运行时的要求
# 安装程序需要系统参数，这些参数会在重新启动时持续存在。

verify() {
  # 校验配置文件
  grep -nE "sandbox|SystemdCgroup" "$CONTAINERD_CONFIG_FILE_PATH"

  ctr -v
  which containerd
}

main () {
  set_containerd_path
  set_url "$url"
  download_ctr_service "$url"

  systemctl daemon-reload
  systemctl enable --now containerd
  systemctl restart containerd
  #systemctl status containerd

  verify
}

main "$@"
