# Cilium
## 先决条件
uname:
参数: 
- -a, --all                按如下次序输出所有信息，其中若 -p 和 -i 的
- 探测结果为未知，则省略：
- -s, --kernel-name        输出内核名称
- -n, --nodename           输出网络节点的主机名
- -r, --kernel-release     输出内核发行号
- -v, --kernel-version     输出内核版本号
- -m, --machine            输出主机的硬件架构名称
- -p, --processor          输出处理器类型（不可移植）
- -i, --hardware-platform  输出硬件平台（不可移植）
- -o, --operating-system   输出操作系统名称


1. 系统内核大于Linux 内核 >= 4.19.57 或同等版本（例如，RHEL8 上的 4.18）
```shell
uname -r
```
3. 采用 AMD64 或 AArch64 架构的主机
```shell
uname -m
```

## 卸载Cilium

在尝试安装完cilium之后，发现运行都crash，查看原因，是内核版本不匹配，需要4.xx，实际我的主机是3.10，所以先准备移除cilium，等待升完内核之后，再来安装。
简单使用

```bash
kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/v1.8/install/kubernetes/quick-install.yaml
```

问题就这样出现了。表面上看似是从集群删除了。但是在其他容器重启或者更新发布之后，发现无法启动了，容器状态一直在containercreating状态。比如

```bash
NAME                                READY   STATUS              RESTARTS   AGE
kibana-9b8ddf948-dn9z6              0/1     ContainerCreating   0          3m2s
```

describe的错误

```bash
  Warning  FailedCreatePodSandBox  3m33s  kubelet, k8s-n1    Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "95ca1afa6b039cb70085e4b9ef3bf99856bf74befdc626576ffa39cea233edf4" network for pod "kibana-9b8ddf948-xxbdx": NetworkPlugin cni failed to set up pod "kibana-9b8ddf948-xxbdx_default" network: unable to connect to Cilium daemon: failed to create cilium agent client after 30.000000 seconds timeout: Get "http:///var/run/cilium/cilium.sock/v1/config": dial unix /var/run/cilium/cilium.sock: connect: no such file or directory
```

### 解决方案

1. 找到这个存放[网络插件](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni)的目录下

```bash
ls /etc/cni/net.d/
05-cilium.conflist      10-flannel.conflist 
```
可以看到有俩文件在这里，而根据官方的说明，它会先加载`kubelet 将会使用按文件名的字典顺序排列的第一个作为配置文件`.所以就选择了05-cilium.conf。

2. 删除这个无用的文件

```bash
rm -f /etc/cni/net.d/05-cilium.conflist
```

3. 删除之后，还需要重启下flannel。
示例:
```bash
kubectl rollout restart daemonsets kube-flannel-ds-amd64 -nkube-system
```

