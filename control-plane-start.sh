#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o errexit -o pipefail

# Control-plane

chmod +x ./control-plane/01-crictl/01-install.sh
chmod +x ./control-plane/01-crictl/02-config.sh
chmod +x ./control-plane/02-init/01-init-kubeadm-config-file.sh
chmod +x ./control-plane/02-init/02-control-plane-init-kubeadm.sh
chmod +x ./control-plane/03-cni/flannel/01-install.sh

./control-plane/01-crictl/01-install.sh
./control-plane/01-crictl/02-config.sh
./control-plane/02-init/01-init-kubeadm-config-file.sh
./control-plane/02-init/02-control-plane-init-kubeadm.sh
./control-plane/03-cni/flannel/01-install.sh

