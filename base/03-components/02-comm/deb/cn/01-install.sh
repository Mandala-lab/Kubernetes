#!/bin/bash

set -e -o posix -o pipefail -x

declare KUBERNETES_VERSION="v1.31"

set_kubernetes_deb_key() {
  sudo curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/${KUBERNETES_VERSION}/deb/Release.key |
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
}

set_kubernetes_apt_repo() {
  echo "添加K8S apt 仓库添加kubernetes apt仓库，这里使用阿里云镜像源，注意此仓库仅包含适用于 K8S 1.31的软件包，对于其他版本，需要自行更改URL中的版本号"
  sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/deb/ /' |
  sudo tee /etc/apt/sources.list.d/kubernetes.list
}

update_apt() {
  echo "更新apt索引"
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
}

lock_kubernetes_version() {
  echo "锁定版本，不随 apt upgrade 更新"
  sudo apt-mark hold kubelet kubeadm kubectl
}

main() {
  set_kubernetes_deb_key
  set_kubernetes_apt_repo
  update_apt
  lock_kubernetes_version
}

main "@"
