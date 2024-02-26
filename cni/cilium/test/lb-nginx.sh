cat > purelb-l2.yaml <<EOF
apiVersion: purelb.io/v1
kind: ServiceGroup
metadata:
  name: layer2-ippool
  namespace: purelb
spec:
  local:
    v4pool:
      subnet: $SUBNET
      pool: $IP_POOL
      aggregation: default
EOF

kubectl apply -f purelb-l2.yaml

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

