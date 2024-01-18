# 

## 使用
要访问 Hubble API，请创建从本地计算机转发到 Hubble 服务的端口。这将允许您将 Hubble 客户端连接到本地端口 4245 并访问 Kubernetes 集群中的 Hubble Relay 服务。有关此方法的更多信息，请参阅使用端口转发访问集群中的应用程序。
```shell
cilium hubble port-forward&
```

现在，您可以验证是否可以通过已安装的 CLI 访问 Hubble API：
```shell
$ hubble status
Healthcheck (via localhost:4245): Ok
Current/Max Flows: 11917/12288 (96.98%)
Flows/s: 11.74
Connected Nodes: 3/3
```

查询流 API 并查找流：
默认值： localhost:4245
```shell
hubble observe
```

```shell
hubble observe --server 0.0.0.0:31234
```


```shell
kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 12000:80
```
