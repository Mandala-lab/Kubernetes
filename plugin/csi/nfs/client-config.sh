#!/bin/bash
set -o posix -o errexit -o pipefail

apt install nfs-common -y

# 用来察看 NFS 分享出来的目录资源
showmount -e 192.168.2.152

set +x
