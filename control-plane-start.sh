#!/usr/bin/env bash
echo "启用 POSIX 模式并设置严格的错误处理机制"
set -e -o posix -o pipefail -x

echo "安装kubectl"
chmod +x ./control-plane/01-kubectl/01-install.sh
./control-plane/01-kubectl/01-install.sh --release="v1.31.1" --ARCH="amd64" --DOWNLOAD_DIR="/usr/local/bin" --DOWNLOAD_HOME="/home/kubernetes"

echo "根据配置生成kubeadm配置文件"
chmod +x ./control-plane/02-init/01-generate-kubeadm-config-file.sh
./control-plane/02-init/01-generate-kubeadm-config-file.sh

echo "根据配置生成kubeadm配置文件预检配置"
chmod +x ./control-plane/02-init/02-pre-check.sh
./control-plane/02-init/02-pre-check.sh

echo "根据kubeadm配置文件初始化kubernetes集群"
#chmod +x ./control-plane/02-init/03-kubeadm-init-file.sh
#./control-plane/02-init/03-kubeadm-init-file.sh

echo "根据kubeadm 命令来初始化kubernetes集群"
chmod +x ./control-plane/02-init/03-kubeadm-init-shell.sh
./control-plane/02-init/03-kubeadm-init-shell.sh

echo "初始化完成之后执行后续步骤"
chmod +x ./control-plane/02-init/04-kubeadm-next.sh
./control-plane/02-init/04-kubeadm-next.sh

echo "最终检查"
chmod +x ./control-plane/verify.sh
./control-plane/verify.sh
