#!/bin/sh

set -x

yum update -y && yum -y install wget psmisc vim net-tools nfs-utils telnet yum-utils device-mapper-persistent-data lvm2 git network-scripts tar curl
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

# 要与master服务器时间同步的IP
export SERVER_HOST="192.168.3.160"

cni_plugins_version='v1.3.0'
cri_containerd_cni_version='1.7.8'
crictl_version='v1.28.0'
cri_dockerd_version='0.3.7'
etcd_version='v3.5.10'
cfssl_version='1.6.4'
kubernetes_server_version='1.28.3'
docker_version='24.0.7'
runc_version='1.1.10'
kernel_version='5.4.260'
helm_version='3.13.2'
nginx_version='1.25.3'

# URLs
base_url='https://mirrors.chenby.cn/https://github.com'
kernel_url="http://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-${kernel_version}-1.el7.elrepo.x86_64.rpm"
runc_url="${base_url}/opencontainers/runc/releases/download/v${runc_version}/runc.amd64"
docker_url="https://mirrors.ustc.edu.cn/docker-ce/linux/static/stable/x86_64/docker-${docker_version}.tgz"
cni_plugins_url="${base_url}/containernetworking/plugins/releases/download/${cni_plugins_version}/cni-plugins-linux-amd64-${cni_plugins_version}.tgz"
cri_containerd_cni_url="${base_url}/containerd/containerd/releases/download/v${cri_containerd_cni_version}/cri-containerd-cni-${cri_containerd_cni_version}-linux-amd64.tar.gz"
crictl_url="${base_url}/kubernetes-sigs/cri-tools/releases/download/${crictl_version}/crictl-${crictl_version}-linux-amd64.tar.gz"
cri_dockerd_url="${base_url}/Mirantis/cri-dockerd/releases/download/v${cri_dockerd_version}/cri-dockerd-${cri_dockerd_version}.amd64.tgz"
etcd_url="${base_url}/etcd-io/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"
cfssl_url="${base_url}/cloudflare/cfssl/releases/download/v${cfssl_version}/cfssl_${cfssl_version}_linux_amd64"
cfssljson_url="${base_url}/cloudflare/cfssl/releases/download/v${cfssl_version}/cfssljson_${cfssl_version}_linux_amd64"
helm_url="https://mirrors.huaweicloud.com/helm/v${helm_version}/helm-v${helm_version}-linux-amd64.tar.gz"
kubernetes_server_url="https://storage.googleapis.com/kubernetes-release/release/v${kubernetes_server_version}/kubernetes-server-linux-amd64.tar.gz"
nginx_url="http://nginx.org/download/nginx-${nginx_version}.tar.gz"

# Download packages
packages=(
  $kernel_url
  $runc_url
  $docker_url
  $cni_plugins_url
  $cri_containerd_cni_url
  $crictl_url
  $cri_dockerd_url
  $etcd_url
  $cfssl_url
  $cfssljson_url
  $helm_url
  $kubernetes_server_url
  $nginx_url
)

for package_url in "${packages[@]}"; do
  filename=$(basename "$package_url")
  if curl --parallel --parallel-immediate -k -L -C - -o "$filename" "$package_url"; then
    echo "Downloaded $filename"
  else
    echo "Failed to download $filename"
    exit 1
  fi
done

sed -ri 's/.*swap.*/#&/' /etc/fstab
swapoff -a && sysctl -w vm.swappiness=0

cat /etc/fstab

systemctl disable --now firewalld

setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

cat > /etc/NetworkManager/conf.d/calico.conf << EOF
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*
EOF
systemctl restart NetworkManager

yum install chrony -y
cat > /etc/chrony.conf << EOF
pool $SERVER_HOST iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd ; systemctl enable chronyd

chronyc sources -v

ulimit -SHn 65535
cat >> /etc/security/limits.conf <<EOF
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* seft memlock unlimited
* hard memlock unlimitedd
EOF




systemctl daemon-reload

systemctl enable --now kubelet
systemctl status kubelet

systemctl enable kubeadm
systemctl status kubeadm

systemctl restart containerd

kubeadm version
kubelet --version
kubectl version --client

# 查看版本的详细视图
# kubectl version --client --output=yaml

# 注意：如果 ipvs 模式成功打开，您应该会看到 IPVS 代理规则（使用 ipvsadm ），例如
# ipvsadm -ln
# IP Virtual Server version 1.2.1 (size=4096)
# Prot LocalAddress:Port Scheduler Flags
#   -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
# TCP  10.0.0.1:443 rr persistent 10800
#   -> 192.168.0.1:6443             Masq    1      1          0

# 或类似的日志出现在 kube-proxy 日志中（例如， /tmp/kube-proxy.log 对于本地集群），当本地集群正在运行时：
# Using ipvs Proxier.
# While there is no IPVS proxy rules or the following logs occurs indicate that the kube-proxy fails to use IPVS mode:
# 虽然没有 IPVS 代理规则或出现以下日志，但表明 kube-proxy 无法使用 IPVS 模式：
# Can't use ipvs proxier, trying iptables proxier
# Using iptables Proxier.

set +x
