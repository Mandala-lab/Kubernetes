#!/bin/bash
set -o posix -o errexit -o pipefail

rm -rf /opt/containerd/
rm -rf /home/containerd
rm -rf /etc/containerd/
rm -rf /etc/systemd/system/containerd.service
rm -rf /etc/modules-load.d/containerd.conf
rm -rf /etc/sysctl.d/99-kubernetes-cri.conf
rm -rf /usr/bin/containerd*
rm -rf /usr/local/bin/container*
rm -rf /run/containerd
rm -rf /var/run/containerd/*
rm -rf /var/lib/containerd
rm -rf sudo apt remove -y containerd
rm -rf /usr/local/bin/ctr

which containerd
hash -r

set +x
