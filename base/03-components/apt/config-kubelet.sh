#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

# 修改kubelet配置文件，使得容器运行时使用的cgroupdriver与kubelet使用的cgroup一致
# https://mp.weixin.qq.com/s/R01pPPLOwcJxYAcMSDGZwA
sudo mkdir -p /etc/sysconfig
sudo chmod -R 777 /etc/sysconfig
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF
sudo systemctl enable kubelet
