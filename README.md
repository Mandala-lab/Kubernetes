# Kubernetes Deploy

## 阶段
目前处在`PRE`初始阶段, 正在快速迭代, 仅在本机MAC环境的aarch64的Ubuntu2.04的虚拟机上测试运行

## 介绍
该仓库旨在快速在Ubuntu一键部署创建一个全新的一个单节点的控制平面

与本仓库同步的文章: https://juejin.cn/post/7292041370893778983

## 注意事项
1. 你需要查看shell的内容, 里面大多包含注释和注意事项
2. 该仓库的脚本不适合用于生产环境的部署, 尽管这些脚本经过本人验证
3. 该项目未对shell脚本进行更多的健壮性校验

## 使用

> 必须安装01的顺序开始进行部署

### Master 控制平面
根据目录的编号执行,一边执行一边查看输出内容是否符合预期

### Worknode 工作节点
执行`01-base`和`02-containerd`脚本和`03-install-worknode-kubernetes.sh`文件, 把在部署Master节点输出的Token进行复制, 即可加入集群

## 局限性
1. 目前仅在Ubuntu22.04上进行开发和测试

## 资料
1. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
2. https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
