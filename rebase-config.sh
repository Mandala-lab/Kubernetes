#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

#/Users/mandala/Public/Golang/project/kubernetes/base/01-env/01-config.sh
cp /etc/hosts{.back,}
systemctl restart systemd-resolved

cp /etc/resolv.conf{.back,}

if [[ -d /etc/selinux && -e /etc/selinux/config  ]]; then
  sudo sed -i 's/^SELINUX=permissive/SELINUX=enforcing$/' /etc/selinux/config # 启用
fi

cp /etc/fstab{.back,}
sudo mount -a

cp /etc/security/limits.conf{,.back}

rm -rf /etc/sysctl.d/99-kubernetes-better.conf
rm -rf /etc/modules-load.d/k8s.conf

if [[ -e /etc/security/limits.d/20-nproc.conf ]];then
  cp /etc/security/limits.d/20-nproc.conf{.back,}
fi

if [[ -e /etc/profile.back ]];then
  cp /etc/profile{.back,}
fi
source /etc/profile
cat /etc/profile
sysctl --system

#/Users/mandala/Public/Golang/project/kubernetes/base/01-env/02-ipvs.sh
rm -rf /etc/sysconfig/modules/ipvs.modules

#/Users/mandala/Public/Golang/project/kubernetes/base/02-cri/containerd/binarymode/01-install.sh
rm -rf /etc/systemd/system/containerd.service
rm -rf /etc/containerd/config.toml

rm -rf /opt/containerd/
rm -rf /usr/bin/ctr
rm -rf /usr/bin/containerd
rm -rf /etc/containerd/
rm -rf /etc/modules-load.d/containerd.conf
rm -rf /etc/sysctl.d/99-kubernetes-cri.conf
hash -r

#/Users/mandala/Public/Golang/project/kubernetes/base/02-cri/containerd/binarymode/repo-proxy.sh
rm -rf /etc/containerd/certs.d
