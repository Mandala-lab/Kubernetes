#!/usr/bin/env bash

# 请注意，由于 Kubernetes 的最终一致性架构，此清单的第一个应用程序可能会失败。
# 发生这种情况的原因是清单既定义了自定义资源定义，又使用该定义创建了资源。
# 如果发生这种情况，请再次应用清单，它应该会成功，因为 Kubernetes 将同时处理定义。
kubectl apply -f https://gitlab.com/api/v4/projects/purelb%2Fpurelb/packages/generic/manifest/0.0.1/purelb-complete.yaml

# 验证安装
kubectl get pods --namespace=purelb --output=wide
