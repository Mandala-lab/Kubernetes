#!/bin/bash
# 此文件是用于下载二进制的Containerd
# 并针对国内服务器进行优化
# 添加镜像拉取的源替换为国内的镜像源

set -e -o posix -o pipefail

[[ "$TRACE" ]] && set -x

set_containerd_path(){
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
  #sed -i 's#sandbox_image = .*#sandbox_image = "k8s.m.daocloud.io:3.9"#' "$CONTAINERD_CONFIG_FILE_PATH"
  sed -i 's#sandbox_image = .*#sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"#' "$CONTAINERD_CONFIG_FILE_PATH"
  grep -nE "sandbox_image" "$CONTAINERD_CONFIG_FILE_PATH"

  # 当 systemd 是选定的初始化系统时, 应当选择SystemdCgroup = true, 否则不需要修改
  # 要在runc中使用 systemd的cgroup 驱动程序，请将 /etc/containerd/config.toml修改SystemdCgroup为true
  # 如果使用 cgroup v2，建议使用 systemd的cgroup 驱动程序
  # 参考: https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/#containerd-systemd
  sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' "$CONTAINERD_CONFIG_FILE_PATH"

  # 下载containerd.service
  # 配置containerd的service单元文件
  # 命令说明:
  # 1. 如果存在containerd.service,内容 可能不是最新的, 而且也会影响下载下来的文件名
  # 删除当前目录的containerd.service, 如果文件不存在, rm -rf 也不会删除, 无需判断文件是否存在
  # 2. 从Github的containerd下载containerd.service文件, 如果下载失败, 则使用内置的文件进行替换
  # 删除旧的containerd.service文件
  rm -rf ./containerd.service
}
set_containerd_path

# 函数：显示错误消息并退出
error_exit() {
    echo "Error: Invalid argument value for $1. Expected 'y' or 'n'."
    exit 1
}

github_proxy=""
install=""
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
        *)  # 处理未知选项
            echo "Error: Unsupported argument $1."
            exit 1
            ;;
    esac
done

url=""
if [ -n "$github_proxy" ];then
  url="${github_proxy}https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"
  else
    url="https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"
fi

# 尝试从GitHub下载containerd.service文件，超时时间为10秒
if ! wget -t 2 -T 30 -N -S $url; then
  echo "下载containerd.service失败, 正在使用内置的文件进行替换, 但可能不是最新的, 可以进行手动替换"
  cat > "$CONTAINERD_SERVICE" << EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

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

# 所有节点均需安装与配置, 根据实际需求, 推荐Kubernetes安装v1.24版本以上使用containerd. 本教程只使用containerd
# 创建/etc/modules-load.d/containerd.conf配置文件，确保在系统启动时自动加载所需的内核模块，以满足容器运行时的要求
# 安装程序需要系统参数，这些参数会在重新启动时持续存在。
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

lsmod | grep br_netfilter

# 应用 sysctl 参数而无需重新启动
sudo sysctl --system

systemctl daemon-reload
systemctl enable --now containerd
systemctl restart containerd
#systemctl status containerd

# 校验配置文件
grep -nE "sandbox_image|SystemdCgroup" "$CONTAINERD_CONFIG_FILE_PATH"

cat /etc/modules-load.d/containerd.conf

ctr -v
which containerd


