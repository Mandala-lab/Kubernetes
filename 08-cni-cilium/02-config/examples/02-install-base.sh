#!/usr/bin/env bash

#export DEVICES="eth0"


#cilium install --version $CILIUM_VERSION \
#--set k8sServiceHost=$HOST \
#--set k8sServicePort=$K8S_API_SERVER_PORT \
#--set cluster.name=$CLUSTER_NAME \
#--set cluster.id=$CLUSTER_ID \
#--set kubeProxyReplacement=true \
#--set nodeinit.enabled=true \
#--set rollOutCiliumPods=true \
#--set bpfClockProbe=true \

helm repo add cilium https://helm.cilium.io/
helm repo update

export DEVICES="enp0s5"
export HOST="192.168.3.160"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="1.15.0-rc.0"
export CLUSTER_NAME="prvite-kubernetes"
export CLUSTER_ID=1
helm install cilium cilium/cilium --version $CILIUM_VERSION \
--namespace kube-system \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set cluster.name=$CLUSTER_NAME \
--set cluster.id="$CLUSTER_ID" \
--set kubeProxyReplacement=true \
--set nodeinit.enabled=true \
--set rollOutCiliumPods=true \
--set routingMode=native \
--set tunnel=disabled \
--set bpf.masquerade=true \
--set bpfClockProbe=true \
--set bpf.preallocateMaps=true \
--set bpf.tproxy=false \
--set bpf.hostLegacyRouting=false \
--set autoDirectNodeRoutes=true \
--set localRedirectPolicy=true \
--set enableCiliumEndpointSlice=true \
--set enableK8sEventHandover=true \
--set externalIPs.enabled=true \
--set hostPort.enabled=true \
--set socketLB.enabled=true \
--set nodePort.enabled=true \
--set sessionAffinity=true \
--set annotateK8sNode=true \
--set nat46x64Gateway.enabled=false \
--set ipv6.enabled=false \
--set pmtuDiscovery.enabled=true \
--set sctp.enabled=true \
--set wellKnownIdentities.enabled=true \
--set hubble.enabled=false \
--set ipv4NativeRoutingCIDR=10.244.0.0/16 \
--set ipam.mode=kubernetes \
--set k8s.requireIPv4PodCIDR=true \
--set k8s.requireIPv6PodCIDR=false \
#--set ipam.operator.clusterPoolIPv4PodCIDRList[0]="10.244.0.0/12" \
--set installNoConntrackIptablesRules=true \
--set enableIPv4BIGTCP=false \
--set enableIPv6BIGTCP=false \
--set egressGateway.enabled=false \
--set endpointRoutes.enabled=false \
--set kubeProxyReplacement=true \
--set highScaleIPcache.enabled=false \
--set l2announcements.enabled=true \
--set k8sClientRateLimit.qps=10 \
--set k8sClientRateLimit.burst=20 \
--set l2podAnnouncements.interface=eth0 \
--set l2announcements.leaseDuration=3s \
--set l2announcements.leaseRenewDeadline=1s \
--set l2announcements.leaseRetryPeriod=200ms \
--set image.useDigest=false \
--set operator.image.useDigest=false \
--set operator.rollOutPods=true \
--set authentication.enabled=false \
--set bandwidthManager.enabled=true \
--set bandwidthManager.bbr=true

sudo rm -rf /root/cilium-linux-amd64.tar.gz /root/cilium-linux-amd64.tar.gz.sha256sum /root/.cache/helm/repository/cilium-index.yaml /root/.cache/helm/repository/cilium-1.14.5.tgz /root/.cache/helm/repository/cilium-charts.txt /usr/local/bin/cilium /var/lib/cni/results/cilium-41d8c697d4564761394da514e386fc1f3ea5ef8597b2994c7c3db640dd375bd3-eth0 /var/lib/cni/results/cilium-a30f32fce53e71b87e446893e2f282cb38ef138255b8c280d182974536793d14-eth0 /var/lib/cni/results/cilium-6167f5f914b3a33b420854769dd61bab702c3b9c8fceee51c7b4535e30a9603d-eth0 /var/lib/cni/results/cilium-a2d2128734e20669a890ae9aed1ff917bef99737c79a8057dc15b4521d984014-eth0 /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6513/fs/home/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-agent /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-bugtool /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-health /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-health-responder /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-mount /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-sysctlfix /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/usr/bin/cilium-dbg /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/etc/bash_completion.d/cilium-dbg /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/var/lib/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6512/fs/opt/cni/bin/cilium-cni /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6350/fs/home/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6509/fs/usr/bin/cilium-envoy /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6509/fs/usr/bin/cilium-envoy-starter /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6506/fs/go/src/github.com/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6506/fs/go/src/github.com/cilium/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6343/fs/go/src/github.com/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6343/fs/go/src/github.com/cilium/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6524/fs/usr/bin/cilium-operator-generic /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6346/fs/usr/bin/cilium-envoy /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium-agent /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium-bugtool /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium-health /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium-health-responder /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium-mount /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/usr/bin/cilium-sysctlfix /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/etc/bash_completion.d/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/var/lib/cilium /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/6349/fs/opt/cni/bin/cilium-cni /tmp/cilium-bootstrap.d /tmp/cilium-bootstrap.d/cilium-bootstrap-time /run/cilium /run/cilium/cilium-cni.log /home/kubernetes/cilium /sys/fs/bpf/cilium /sys/fs/bpf/tc/globals/cilium_calls_netdev_00002 /sys/fs/bpf/tc/globals/cilium_calls_netdev_00003 /sys/fs/bpf/tc/globals/cilium_calls_hostns_01367 /sys/fs/bpf/tc/globals/cilium_calls_01249 /sys/fs/bpf/tc/globals/cilium_calls_02302 /sys/fs/bpf/tc/globals/cilium_calls_00352 /sys/fs/bpf/tc/globals/cilium_calls_00087 /sys/fs/bpf/tc/globals/cilium_calls_00111 /sys/fs/bpf/tc/globals/cilium_policy_00087 /sys/fs/bpf/tc/globals/cilium_ipcache /sys/fs/bpf/tc/globals/cilium_policy_02302 /sys/fs/bpf/tc/globals/cilium_policy_00352 /sys/fs/bpf/tc/globals/cilium_policy_01249 /sys/fs/bpf/tc/globals/cilium_policy_00111 /sys/fs/bpf/tc/globals/cilium_policy_01367 /sys/fs/bpf/tc/globals/cilium_ratelimit /sys/fs/bpf/tc/globals/cilium_encrypt_state /sys/fs/bpf/tc/globals/cilium_l2_responder_v4 /sys/fs/bpf/tc/globals/cilium_lb4_source_range /sys/fs/bpf/tc/globals/cilium_lb4_affinity /sys/fs/bpf/tc/globals/cilium_lb_affinity_match /sys/fs/bpf/tc/globals/cilium_ipv4_frag_datagrams /sys/fs/bpf/tc/globals/cilium_nodeport_neigh4 /sys/fs/bpf/tc/globals/cilium_snat_v4_external
