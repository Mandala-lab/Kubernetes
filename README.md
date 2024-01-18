# Kubernetes Deploy

## 阶段
目前处在`PRE`初始阶段, 正在快速迭代, 仅在本机MAC环境的aarch64的Ubuntu2.04的虚拟机上测试运行

## 介绍
该仓库旨在快速在Ubuntu一键部署创建一个全新的一个单节点的控制平面

与本仓库同步的文章: https://juejin.cn/post/7292041370893778983

## 说明
| 目录                     | 角色            | 作用                   | 备注                                      |
|------------------------|---------------|----------------------|-----------------------------------------|
| 01-base-env            | ALL           | 安装与配置Kubernetes所需的环境 | 当前仅适用于Ubuntu发行版                         |
| 02-CRI                 | ALL           | 安装与配置CRI容器运行时        | 当前只适配Containerd                         |
| 03-CNI                 |               | 安装与配置CNI             | 如果是kube-proxy组件,则需要安装                   |
| 04-cgroup              | ALL           | 配置cgroup             | 当前仅适用于Ubuntu发行版                         |
| 05-crictl              | Control plane | 安装与配置crictl          | 二进制安装需要单独安装, 包管理器安装的方式已经安装该工具. 但它们都需要配置 |
| 06-apt-init-components | ALL           | 安装Kubernetes组件与初始化集群 | 当前仅适合Ubuntu                             |

## 注意事项
1. 你需要查看shell的内容, 里面大多包含注释和注意事项
2. 该仓库的脚本不适合用于生产环境的部署, 尽管这些脚本经过本人验证
3. 该项目未对shell脚本进行更多的健壮性校验

## 使用

在目标服务器安装:
```shell
git clone --depth 1 https://github.com/Mandala-lab/Kubernetes.git
```

### Master 控制平面
#### Cilium
##### Base 基本安装
chmod +x ./base-env-apt-cilium-install.sh
./base-env-apt-cilium-install.sh

### Worknode 工作节点


## 局限性
1. 目前仅在Ubuntu22.04上进行开发和测试
2. 需要在拥有管理员执行的权限才可以运行shell scripts
3. 本集群是在管理员权限的情况下部署, 不适用于对安全性有苛刻要求的环境

## 资料
1. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
2. https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
