#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

# 定义可用的版本列表
kubernetes_versions=("v1.32" "v1.31" "v1.30" "v1.29")
current_selection=0  # 当前选中的索引

echo "目前由于kubernetes官方变更了仓库的存储路径以及使用方式，旧版 kubernetes 源只更新到 1.28 部分版本，本人懒,不另写旧源的方法"

# 打印菜单
print_menu() {
    clear
    echo "请选择一个 Kubernetes 版本 (使用上下箭头选择，按 Enter 确认)："
    for i in "${!kubernetes_versions[@]}"; do
        if [ "$i" -eq "$current_selection" ]; then
            echo -e "\e[7m> ${kubernetes_versions[$i]}\e[0m"  # 高亮显示当前选中的选项
        else
            echo "  ${kubernetes_versions[$i]}"
        fi
    done
}

# 处理用户输入
handle_input() {
    read -rsn1 key  # 读取一个字符

    case "$key" in
        A)  # 上箭头
            if [ "$current_selection" -gt 0 ]; then
                ((current_selection--))
            fi
            ;;
        B)  # 下箭头
            if [ "$current_selection" -lt $((${#kubernetes_versions[@]} - 1)) ]; then
                ((current_selection++))
            fi
            ;;
        "")  # Enter 键
            selected_version="${kubernetes_versions[$current_selection]}"
            return 0
            ;;
        *)  # 其他键
            ;;
    esac

    return 1
}

# 主循环
select_kubernetes_version() {
    while true; do
        print_menu
        if handle_input; then
            break
        fi
    done

    # 输出用户选择的版本
    if [ -n "$selected_version" ]; then
        echo "你选择了 Kubernetes 版本: $selected_version"
    else
        echo "没有选择任何版本，退出。"
        exit 1
    fi
}

check_dir() {
  echo "判断 /etc/apt/keyrings 目录是否存在"
  if [[ ! -e /etc/apt/keyrings || ! -d /etc/apt/keyrings ]]; then
    echo "目录不存在, 创建"
    sudo mkdir -p -m 755 /etc/apt/keyrings
  else
    echo "目录已存在"
  fi
}

add_kubernetes_apt() {
  rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  rm -rf /etc/apt/sources.list.d/kubernetes.list
  apt-get update && apt-get install -y apt-transport-https
  curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/"${kubernetes_versions[$current_selection]}"/deb/Release.key |
      gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/${kubernetes_versions[$current_selection]}/deb/ /" |
      tee /etc/apt/sources.list.d/kubernetes.list
}

update_apt() {
  echo "更新 apt 索引"
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm
}

lock_kubernetes_version() {
  echo "锁定版本，不随 apt upgrade 更新"
  sudo apt-mark hold kubelet kubeadm
}

main() {
  select_kubernetes_version
  check_dir
  add_kubernetes_apt
  update_apt
  lock_kubernetes_version

  echo "Kubernetes 安装完成，客户端版本如下："
  kubeadm version
  kubelet --version
}

# 调用 main 函数
main
