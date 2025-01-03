#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

update_apt() {
  echo "更新apt索引"
  sudo apt-get update
  sudo apt-get install -y kubectl
}

lock_kubernetes_version() {
  echo "锁定版本，不随 apt upgrade 更新"
  sudo apt-mark hold kubectl
}

main() {
  update_apt
  lock_kubernetes_version

  kubectl version --client
}

main "@"

# 查看版本的详细视图
# kubectl version --client --output=yaml
