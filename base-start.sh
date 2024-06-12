#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

# Base

chmod +x ./base/01-env/deb/01-config.sh
./base/01-env/deb/01-config.sh

chmod +x ./base/01-env/deb/02-allow-port.sh
./base/01-env/deb/02-allow-port.sh

chmod +x ./base/02-cri/containerd/binarymode/01-install.sh
./base/02-cri/containerd/binarymode/01-install.sh

chmod +x ./base/02-cri/containerd/binarymode/02-config.sh
./base/02-cri/containerd/binarymode/02-config.sh

chmod +x ./base/02-cri/containerd/binarymode/03-install-runc.sh
./base/02-cri/containerd/binarymode/03-install-runc.sh

chmod +x ./base/02-cri/containerd/binarymode/03-repo.sh
./base/02-cri/containerd/binarymode/03-repo.sh

chmod +x ./base/03-components/deb/template.sh
./base/03-components/deb/template.sh

chmod +x ./base/03-components/deb/01-install-control-plane-components.sh
./base/03-components/deb/01-install-control-plane-components.sh

