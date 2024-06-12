#!/bin/sh
set -o posix errexit -o pipefail

apt install -y nfs-kernel-server #安装nfs服务
apt install -y nfs-common
# 创建共享目录
mkdir -p /mnt/data

systemctl start rpcbind ##先启动rpc服务
systemctl start nfs-kernel-server #nfs

#设置开机启动
systemctl enable rpcbind
#设置开机启动
systemctl enable nfs-kernel-server

# #启动nfs服务和nfs安全传输服务
# 配置防火墙放行nfs服务
firewall-cmd --permanent --add-service=nfs
firewall-cmd  --reload

# 首先创建共享目录，然后
# 这是 NFS 的主要配置文件。该文件是空白的，有的系统可能不存在这个文件，主要手动建立。
# NFS的配置一般只在/etc/exports这个文件中配置即可
cat >> /etc/exports << EOF
/mnt/data/ 192.168.2.155(rw,async,no_root_squash)
/mnt/data/ 192.168.2.158(rw,async,no_root_squash)
/mnt/data/ 192.168.2.160(rw,async,no_root_squash)
/mnt/data/ 192.168.2.100(rw,async,no_root_squash)
/mnt/data/ 192.168.2.101(rw,async,no_root_squash)
/mnt/data/ 192.168.2.102(rw,async,no_root_squash)
EOF

#重新加载NFS服务，使配置文件生效
systemctl reload nfs-kernel-server

systemctl status rpcbind ##先启动rpc服务
systemctl status nfs-kernel-server #nfs

# 用来察看 NFS 分享出来的目录资源
showmount -e 192.168.2.152

set +x
