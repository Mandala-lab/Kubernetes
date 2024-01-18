#!/usr/bin/env bash

# https://zhuanlan.zhihu.com/p/519440676

cat > purelb-ipam-l2-1.yaml <<EOF
apiVersion: purelb.io/v1
kind: ServiceGroup
metadata:
  name: ip-pool-1
  namespace: purelb
spec:
  local:
    v4pools:
    - subnet: '192.168.2.168/25'
      pool: '192.168.2.170-192.168.2.199'
      aggregation: default
EOF

cat > purelb-ipam-l2-2.yaml <<EOF
apiVersion: purelb.io/v1
kind: ServiceGroup
metadata:
  name: default
  namespace: purelb
spec:
  local:
    v4pools:
    - subnet: '192.168.2.192/27'
      pool: '192.168.2.193-192.168.2.254'
      aggregation: default
EOF

kubectl apply -f purelb-l2.yaml

ct get sg -n purelb
kubectl describe -n purelb lbnodeagent.purelb.io/default
kubectl describe sg -n purelb

# test lb
cat > test-l2-lb-nginx.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: nginx-quic
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-lb
  namespace: nginx-quic
spec:
  selector:
    matchLabels:
      app: nginx-lb
  replicas: 4
  template:
    metadata:
      labels:
        app: nginx-lb
    spec:
      containers:
      - name: nginx-lb
        image: tinychen777/nginx-quic:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    purelb.io/service-group: layer2-ippool
  name: nginx-lb-service
  namespace: nginx-quic
spec:
  allocateLoadBalancerNodePorts: false
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  selector:
    app: nginx-lb
  ports:
  - protocol: TCP
    port: 80 # match for service access port
    targetPort: 80 # match for pod access port
  type: LoadBalancer
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    purelb.io/service-group: layer2-ippool
  name: nginx-lb2-service
  namespace: nginx-quic
spec:
  allocateLoadBalancerNodePorts: false
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  selector:
    app: nginx-lb
  ports:
  - protocol: TCP
    port: 80 # match for service access port
    targetPort: 80 # match for pod access port
  type: LoadBalancer
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    purelb.io/service-group: layer2-ippool
  name: nginx-lb3-service
  namespace: nginx-quic
spec:
  allocateLoadBalancerNodePorts: false
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  selector:
    app: nginx-lb
  ports:
  - protocol: TCP
    port: 80 # match for service access port
    targetPort: 80 # match for pod access port
  type: LoadBalancer
EOF

kubectl apply -f test-l2-lb-nginx.yaml

kubectl get svc -n nginx-quic

kubectl describe service nginx-lb-service -n nginx-quic
kubectl describe service nginx-lb2-service -n nginx-quic
kubectl describe service nginx-lb3-service -n nginx-quic

server {
    listen 31100;
    http2 on;
    # add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    # add_header X-XSS-Protection "1; mode=block" always;
    # add_header X-Frame-Options SAMEORIGIN always;
    # add_header X-Content-Type-Options nosniff;
    # add_header X-Frame-Options "DENY";
    # add_header Alt-Svc 'h3=":443"; ma=86400, h3-29=":443"; ma=86400';
    # proxy_connect_timeout 5s;
    #添加 Early-Data 头告知后端，防止重放攻击
    #proxy_set_header Early-Data $ssl_early_data;
    #proxy_set_header Host $host;
    #proxy_set_header X-Real-IP $remote_addr;
    #proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    location / {
            proxy_pass http://192.168.2.170:80;  # Kubernetes集群中应用的地址和端口
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}
