# Kubernetes分布式存储

## 前置
1. [在Linux部署NFS的服务](https://juejin.cn/post/7317260317620240447)
2. 至少2台机器

## 创建命名空间
```shell
kubectl create namespace clusterstorage
```

## nfs storageClass 部署

修改`storageclass-nfs.yaml`文件的`server`和`path`改成自己`nfs服务器`配置, 例如:
```yaml
...
parameters:
  # 填写为/etc/exports的IP
  server: 192.168.2.152
  # 填写为/etc/exports的挂载地址
  share: /mnt/data/
...
```

启动
```shell
kubectl apply -f .
```

查看
```shell
kubectl -n clusterstorage get pod -owide
```

## 测试
```shell
kubectl get sc
```

示例输出:
```
NAME                PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-csi (default)   nfs.csi.k8s.io   Delete          Immediate           true                   7m7s
```

运行测试:
```shell
kubectl apply -f ./test
```

查看测试结果, 如果`test-nfs-pod`这个Pod的状态为`Completed`则表示测试成功:
```shell
kubectl describe po test-nfs-pod
```

查看PVC是否绑定:
```shell
kubectl get pvc
```

```
NAME         STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
nfs-claim1   Bound    nfs-claim1   1Gi        RWO            nfs-csi        <unset>                 3m13s
```

查看PV是否创建:
```shell
kubectl get pv
```

```
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
nfs-claim1   1Gi        RWO            Retain           Bound    default/nfs-claim1   nfs-csi        <unset>                          3m54s
```

## 清理
清理测试用例:
```shell
cd kubernetes-csi-nfs
kubectl delete -f ./test
```

完全清理本分布式存储:
```shell
cd kubernetes-csi-nfs
kubectl delete -f .
```

## 错误处理

自行检测以下问题:
1. 没有在控制平面节点安装NFS服务
2. 没有在工作节点安装NFS客户端库
3. 没有在`storageclass-nfs.yaml`文件的`server`和`path`改成自己`nfs服务器`配置
