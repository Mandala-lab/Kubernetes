# 取消kubelet的挂载
sudo umount /var/lib/kubelet/pods/*

# 停止正在运行的容器和删除这些容器的镜像
crictl images | awk '{print $3}' | xargs -n 1 crictl rmi

# 用crictl命令停止和删除不存在的容器
if [ -n "$running_containers" ]; then
    # Stop and remove running containers
    echo "Stopping and removing running containers..."
    echo "$running_containers" | xargs -n 1 crictl stop
    echo "$running_containers" | xargs -n 1 crictl rm
else
    echo "No running containers found."
fi

# 删除未使用(非正在运行的)的镜像
crictl rmi --prune

systemctl stop kubeadm
systemctl stop kubelet
systemctl stop kubectl

# configfile
sudo rm -rf /etc/modules-load.d/k8s.conf
sudo rm -rf /etc/modules-load.d/ipvs.conf
sudo rm -rf /lib/systemd/system/kube*
sudo rm -rf /etc/sysctl.d/99-sysctl.conf
sudo rm -rf /etc/sysctl.d/99-zzz-override_cilium.conf
sudo rm -rf /etc/sysctl.d/99-kubernetes-cri.conf
sudo rm -rf /etc/sysctl.d/10-network-security.conf
sudo rm /etc/cni/net.d/05-cilium.conf

# service
rm -rf /etc/systemd/system/kube*

# sock
rm -rf /var/run/kubeadm/*
rm -rf /var/run/kubelet/*
rm -rf /run/kubeadm/*
rm -rf /run/kubelet/*

systemctl disenable kubeadm
systemctl disenable kubelet
systemctl disenable kubectl

# 删除Kubernetes的配置与安装的包
sudo apt purge -y kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-mark unhold kubeadm
sudo apt-mark unhold kubelet
sudo apt-mark unhold kubectl
sudo apt remove -y kubeadm kubelet kubectl

rm -rf /etc/apt/keyrings/*
rm -rf /usr/lib/systemd/system/kubelet.service
rm -rf /usr/lib/systemd/system/kubelet.service.d

# 清理旧的安装信息
which kubeadm kubelet kubectl
hash -r

# 自动删除不需要的依赖项：
#sudo apt autoremove -y

# 清理Docker容器和镜像（如果使用Docker）：
#docker image prune -a -f
#systemctl restart docker
#sudo apt purge -y docker-engine docker docker.io docker-ce docker-ce-cli containerd containerd.io runc --allow-change-held-packages

# 删除网卡
apt install net-tools # Ubuntu
yum install net-tools # RedHat

# 重置节点
kubeadm reset -f

# flannel
ifconfig flannel.1 down
ip link delete flannel.1

# CNI
ifconfig cni0 down
ip link delete cni0

# kube-ipvs0
ifconfig kube-ipvs0 down
ip link delete kube-ipvs0

ifconfig cilium_netdown
ip link delete kube-cilium_netdown

ifconfig cilium_host down
ip link delete cilium_host

ifconfig cilium_vxlan down
ip link delete cilium_vxlan

# 清理iptables规则：
sudo iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

# 清理IPVS规则
sudo ipvsadm -C

sudo rm -rf /etc/kubernetes/ # Kubernetes的安装位置

# 删除Kubernetes的相关依赖
sudo rm -rf \
/var/lib/cni \
/var/lib/etcd \
/var/lib/dockershim \
/var/lib/kubelet \
/etc/cni \
/opt/cni \
/opt/cni/bin \
/etc/kubernetes  \
/var/run/kubernetes \
~/.kube/* \
/usr/local/bin/kube* \
/usr/local/bin/crictl \
/etc/sysconfig/kubelet \
/etc/kubernetes

crictl -v
ctr -v
socat -h
runc -h
conntrack -h
#ipvsadm -h
