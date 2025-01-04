#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

# 定义可用的版本列表
kubernetes_version=("v1.32" "v1.31" "v1.30" "v1.29")
current_selection=0  # 当前选中的索引

check_dir() {
  echo "判断/etc/apt/keyrings命令是否存在"
  if [[ -e /etc/apt/keyrings && -d /etc/apt/keyrings ]]; then
    echo "目录不存在,创建"
    sudo mkdir -p -m 755 /etc/apt/keyrings
  fi
}

add_kubernetes_apt() {
  echo "添加 Kubernetes apt 仓库。 请注意，此仓库仅包含适用于 Kubernetes 1.31 的软件包； 对于其他 Kubernetes 次要版本，则需要更改 URL 中的 Kubernetes 次要版本以匹配你所需的次要版本 （你还应该检查正在阅读的安装文档是否为你计划安装的 Kubernetes 版本的文档）"
  curl -fsSL https://pkgs.k8s.io/core:/stable:/"${kubernetes_version}"/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${kubernetes_version}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  cat /etc/apt/sources.list.d/kubernetes.list
}

update_apt() {
  echo "更新apt索引"
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm
}

lock_kubernetes_version() {
  echo "锁定版本，不随 apt upgrade 更新"
  sudo apt-mark hold kubelet kubeadm
}

main() {
  check_dir
  add_kubernetes_apt
  update_apt
  lock_kubernetes_version
}

main "@"

# 查看版本的详细视图
# kubectl version --client --output=yaml
