#!/bin/bash

cat > net-tools.yaml <<EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: net-tools
  labels:
    k8s-app: net-tools
spec:
  selector:
    matchLabels:
      k8s-app: net-tools
  template:
    metadata:
      labels:
        k8s-app: net-tools
    spec:
      tolerations:
        - effect: NoSchedule
          operator: Exists
        - key: CriticalAddonsOnly
          operator: Exists
        - effect: NoExecute
          operator: Exists
      containers:
        - name: net-tools
          image: juestnow/net-tools
          command:
            - /bin/sh
            - "-c"
            - set -e -x; tail -f /dev/null
          resources:
            limits:
              memory: 30Mi
            requests:
              cpu: 50m
              memory: 20Mi
      dnsConfig:
        options:
          - name: single-request-reopen

EOF

kubectl create -f net-tools.yaml
