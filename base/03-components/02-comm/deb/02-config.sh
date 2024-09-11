#!/bin/bash

set -e -o posix -o pipefail -x
#配置kubelet

set_kubelet_config() {
  echo "修改kubelet配置文件，使得容器运行时使用的cgroupdriver与kubelet使用的cgroup一致"
  sudo mkdir -p /etc/sysconfig
  sudo chmod -R 777 /etc/sysconfig

  cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF
  cat /etc/sysconfig/kubelet
  sudo systemctl enable kubelet
}

main() {
  set_kubelet_config
}

main "@"
