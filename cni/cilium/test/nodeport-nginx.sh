kubectl create ns nginx-quic
cat > test-l2-lb-nginx.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF

kubectl apply -f test-l2-lb-nginx.yaml -n nginx-quic

kubectl get po,svc -n nginx-quic

kubectl describe service nginx-lb-service -n nginx-quic
kubectl describe service nginx-lb2-service -n nginx-quic
kubectl describe service nginx-lb3-service -n nginx-quic

