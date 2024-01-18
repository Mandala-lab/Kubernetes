#!/usr/bin/env bash

helm repo add purelb https://gitlab.com/api/v4/projects/20400619/packages/helm/stable
helm repo update
helm install \
--create-namespace \
--namespace=purelb \
--set=lbnodeagent.sendgarp=true \
purelb/purelb

# 验证安装
kubectl get pods --namespace=purelb --output=wide
