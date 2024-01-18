# PureLB

## 使用

配置文件:
标准的配置文件:
```yaml
apiVersion: purelb.io/v1
kind: ServiceGroup
metadata:
  name: default
  namespace: purelb
spec:
  local:
    v4pools:
    - subnet: 192.168.254.0/24
      pool: 192.168.254.230/32
      aggregation: default
    - subnet: 192.168.254.0/24
      pool: 192.168.254.231-192.168.254.240
      aggregation: default
    v6pools:
    - subnet: fd53:9ef0:8683::/120
      pool: fd53:9ef0:8683::-fd53:9ef0:8683::3
      aggregation: default
```

参数说明:
IPv4: 
.spec.local.v4pools: 本地ipv4地址池
.spec.local.v4pools.subnet: 包含所有池地址的子网。PureLB 使用此信息来计算如何将地址添加到集群中。
.spec.local.v4pools.pool: 将分配的地址的特定范围。可以表示为 CIDR 或地址范围
.spec.local.v4pools.aggregation: 聚合器将已分配地址的地址掩码从子网的掩码更改为指定的掩码

IPv6:
.spec.local.v6pools: 本地ipv6地址池
.spec.local.v6pools.subnet: 包含所有池地址的子网。PureLB 使用此信息来计算如何将地址添加到集群中。
.spec.local.v6pools.pool: 将分配的地址的特定范围。可以表示为 CIDR 或地址范围
.spec.local.v6pools.aggregation: 聚合器将已分配地址的地址掩码从子网的掩码更改为指定的掩码

在svc添加注解:

把`<ipam-name>`替换成你的ipam名称
```yaml
kubectl annotate svc <your-service-name> purelb.io/service-group=layer2-ippool
```

或者手动编辑:
```shell
kubectl edit svc <your-service-name>
```
然后再metadata.annotations下添加`purelb.io/service-group: <ipam-name>`
```

...
metadata:
    annotations:
        purelb.io/service-group: layer2-ippool
...
```

## 资料
1. https://purelb.gitlab.io/docs/install/
