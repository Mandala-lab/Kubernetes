#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail
kubeadm init \
--kubernetes-version=1.30.2 \
--control-plane-endpoint="192.168.3.100" \
--apiserver-bind-port="6443" \
--image-repository=registry.aliyuncs.com/google_containers \
--service-cidr=10.96.0.0/12 \
--pod-network-cidr=10.244.0.0/16 \
--cri-socket=unix:///var/run/containerd/containerd.sock \
--upload-certs \
--skip-phases=addon/kube-proxy \
 --v=7

mount | grep /sys/fs/bpf

kubectl -n kube-system delete ds kube-proxy
kubectl -n kube-system delete cm kube-proxy
# Run on each node with root permissions:
iptables-save | grep -v KUBE | iptables-restore



CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_NET_CLS_BPF=y
CONFIG_BPF_JIT=y
CONFIG_NET_CLS_ACT=y
CONFIG_NET_SCH_INGRESS=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_USER_API_HASH=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_BPF=y
CONFIG_PERF_EVENTS=y
CONFIG_SCHEDSTATS=y

# 带宽管理器的要求
CONFIG_NET_SCH_FQ=m

# 防火墙
## master
sudo ufw status
sudo ufw allow 2379:2380/tcp
sudo ufw allow 8472/udp
sudo ufw allow 4240/tcp
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
sudo ufw allow 4240/tcp
sudo ufw allow 4244/tcp
sudo ufw allow 4245/tcp
sudo ufw allow 6060/tcp
sudo ufw allow 6062/tcp
sudo ufw allow 9879/tcp
sudo ufw allow 9890/tcp
sudo ufw allow 9891/tcp
sudo ufw allow 9892/tcp
sudo ufw allow 9893/tcp
sudo ufw allow 9962/tcp
sudo ufw allow 9964/tcp
sudo ufw allow 51871/udp

## worker node
sudo ufw allow 8472/tcp
sudo ufw allow 4240/tcp
sudo ufw allow 8472/udp
sudo ufw allow 2379-2380/tcp
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
sudo ufw allow 4240/tcp
sudo ufw allow 4244/tcp
sudo ufw allow 4245/tcp
sudo ufw allow 6060/tcp
sudo ufw allow 6062/tcp
sudo ufw allow 9879/tcp
sudo ufw allow 9890/tcp
sudo ufw allow 9891/tcp
sudo ufw allow 9892/tcp
sudo ufw allow 9893/tcp
sudo ufw allow 9962/tcp
sudo ufw allow 9964/tcp
sudo ufw allow 51871/udp

cat > /etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 node1

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

192.168.3.100 node1
192.168.3.101 node2
192.168.3.102 node3
EOF
cat /etc/hosts

API_SERVER_IP="192.168.3.100"
API_SERVER_PORT="6443"
helm install cilium ./cilium --version 1.15.6 \
--namespace kube-system \
--set routingMode="native" \
--set autoDirectNodeRoutes=true \
--set ipv4NativeRoutingCIDR=10.0.0.0/22 \
--set enableIPv4Masquerade=true \
--set kubeProxyReplacement=true \
--set k8sServiceHost=${API_SERVER_IP} \
--set k8sServicePort=${API_SERVER_PORT} \

--set bpf.masquerade=true \
--set ipMasqAgent.enabled=true \

 --set loadBalancer.mode=dsr \
    --set loadBalancer.dsrDispatch=opt \


# helm uninstall cilium -n kube-system

kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement
# 完整详细信息：
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose

cat > nginx_test.yml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF
kubectl create -f nginx_test.yml
kubectl get pods -l run=my-nginx -o wide
kubectl expose deployment my-nginx --type=NodePort --port=80
kubectl get svc my-nginx

kubectl -n kube-system exec ds/cilium -- cilium-dbg service list
nohup cilium connectivity test &
tail -f nohup.out

kubectl --namespace kube-system get ds

# 识别失败的 pod
kubectl --namespace kube-system get pods --selector k8s-app=cilium \
          --sort-by='.status.containerStatuses[0].restartCount'

helm upgrade cilium ./cilium --version 1.15.6 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true

HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}

cilium hubble port-forward&
hubble status

# 查询流 API 并查找流：
hubble observe
