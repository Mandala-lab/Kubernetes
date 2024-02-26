#!/bin/bash

export HOST="192.168.3.155"
export CIDR="192.168.3.155/24"
export GATEWAY="192.168.3.1"
export DNS1="192.168.3.1"
export DNS2="8.8.8.8"
export DNS3="180.184.1.1"
export DNS4="223.5.5.5"
export OLD_DEVICE="enp0s5"
export NEW_DEVICE="eth0"
nmcli con show
export UUID="37f81a00-7bc2-38d5-bb73-96ea558d488a"

# 查看网卡配置
nmcli device show $DEVICE

# 1.2.配置IP
# 注意！
# 若虚拟机是进行克隆的那么网卡的UUID会重复
# 若UUID重复需要重新生成新的UUID
# UUID重复无法获取到IPV6地址
#
# 查看当前的网卡列表和 UUID：
# nmcli con show
# 删除要更改 UUID 的网络连接：
# nmcli con delete uuid <原 UUID>
# 重新生成 UUID：
# nmcli con add type ethernet ifname <接口名称> con-name <新名称>
# 重新启用网络连接：
# nmcli con up <新名称>


# 参数解释
#
# ssh ssh root@192.168.1.31
# 使用SSH登录到IP为192.168.1.31的主机，使用root用户身份。
#
# nmcli con delete uuid 708a1497-2192-43a5-9f03-2ab936fb3c44
# 删除 UUID 为 708a1497-2192-43a5-9f03-2ab936fb3c44 的网络连接，这是 NetworkManager 中一种特定网络配置的唯一标识符。
#
# nmcli con add type ethernet ifname eth0 con-name eth0
# 添加一种以太网连接类型，并指定接口名为 eth0，连接名称也为 eth0。
#
# nmcli con up eth0
# 开启 eth0 这个网络连接。
#
# 简单来说，这个命令的作用是删除一个特定的网络连接配置，并添加一个名为 eth0 的以太网连接，然后启用这个新的连接。
nmcli con delete uuid $UUID

nmcli con show

nmcli con add type ethernet ifname $OLD_DEVICE con-name $NEW_DEVICE
nmcli con mod $NEW_DEVICE ipv4.addresses $CIDR
nmcli con mod $NEW_DEVICE ipv4.method manual
nmcli con mod $NEW_DEVICE ipv4.gateway $GATEWAY
nmcli con mod $NEW_DEVICE ipv4.dns $DNS1,$DNS2,$DNS3,$DNS4
nmcli con mod $NEW_DEVICE ipv4.addresses $HOST
nmcli con mod $NEW_DEVICE ipv4.method manual;
nmcli con up $NEW_DEVICE
# 参数解释

# 查看网卡配置
nmcli device show $DEVICE
nmcli con show $DEVICE



# 参数解释
#
# TYPE=Ethernet
# 指定连接类型为以太网。
#
# PROXY_METHOD=none
# 指定不使用代理方法。
#
# BROWSER_ONLY=no
# 指定不仅仅在浏览器中使用代理。
#
# BOOTPROTO=none
# 指定自动分配地址的方式为无（即手动配置IP地址）。
#
# DEFROUTE=yes
# 指定默认路由开启。
#
# IPV4_FAILURE_FATAL=no
# 指定IPv4连接失败时不宣告严重错误。
#
# IPV6INIT=yes
# 指定启用IPv6。
#
# IPV6_AUTOCONF=no
# 指定不自动配置IPv6地址。
#
# IPV6_DEFROUTE=yes
# 指定默认IPv6路由开启。
#
# IPV6_FAILURE_FATAL=no
# 指定IPv6连接失败时不宣告严重错误。
#
# IPV6_ADDR_GEN_MODE=stable-privacy
# 指定IPv6地址生成模式为稳定隐私模式。
#
# NAME=eth0
# 指定设备名称为eth0。
#
# UUID=424fd260-c480-4899-97e6-6fc9722031e8
# 指定设备的唯一标识符。
#
# DEVICE=eth0
# 指定设备名称为eth0。
#
# ONBOOT=yes
# 指定开机自动启用这个连接。
#
# IPADDR=192.168.1.31
# 指定IPv4地址为192.168.1.31。
#
# PREFIX=24
# 指定IPv4地址的子网掩码为24。
#
# GATEWAY=192.168.8.1
# 指定IPv4的网关地址为192.168.8.1。
#
# DNS1=8.8.8.8
# 指定首选DNS服务器为8.8.8.8。
#
# IPV6ADDR=fc00:43f4:1eea:1::10/128
# 指定IPv6地址为fc00:43f4:1eea:1::10，子网掩码为128。
#
# IPV6_DEFAULTGW=fc00:43f4:1eea:1::1
# 指定IPv6的默认网关地址为fc00:43f4:1eea:1::1。
#
# DNS2=2400:3200::1
# 指定备用DNS服务器为2400:3200::1。
1.3.设置主机名
hostnamectl set-hostname k8s-master01
hostnamectl set-hostname k8s-master02
hostnamectl set-hostname k8s-master03
hostnamectl set-hostname k8s-node01
hostnamectl set-hostname k8s-node02

# 参数解释
#
# 参数: set-hostname
# 解释: 这是hostnamectl命令的一个参数，用于设置系统的主机名。
#
# 参数: k8s-master01
# 解释: 这是要设置的主机名，将系统的主机名设置为"k8s-master01"。
1.4.配置yum源
# 其他系统的源地址
# https://mirrors.tuna.tsinghua.edu.cn/help/

# 对于 Ubuntu
sed -i 's/cn.archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# 对于 CentOS 7
sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo

# 对于 CentOS 8
sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo

# 对于私有仓库
sed -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://mirror.centos.org/\$contentdir|baseurl=http://192.168.1.123/centos|g' -i.bak  /etc/yum.repos.d/CentOS-*.repo

# 参数解释
#
# 以上命令是用于更改系统软件源的配置，以便从国内镜像站点下载软件包和更新。
#
# 对于 Ubuntu 系统，将 /etc/apt/sources.list 文件中的软件源地址 cn.archive.ubuntu.com 替换为 mirrors.ustc.edu.cn。
#
# 对于 CentOS 7 系统，将 /etc/yum.repos.d/CentOS-*.repo 文件中的 mirrorlist 注释掉，并将 baseurl 的值替换为 https://mirrors.tuna.tsinghua.edu.cn/centos。
#
# 对于 CentOS 8 系统，同样将 /etc/yum.repos.d/CentOS-*.repo 文件中的 mirrorlist 注释掉，并将 baseurl 的值替换为 https://mirrors.tuna.tsinghua.edu.cn/centos。
#
# 对于私有仓库，将 /etc/yum.repos.d/CentOS-*.repo 文件中的 mirrorlist 注释掉，并将 baseurl 的值替换为私有仓库地址 http://192.168.1.123/centos。
#
# 这些命令通过使用 sed 工具和正则表达式，对相应的配置文件进行批量的替换操作，从而更改系统软件源配置。
