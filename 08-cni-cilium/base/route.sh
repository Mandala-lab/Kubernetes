#!/usr/bin/env bash

ip r

default via 192.168.2.1 dev ens160 proto static
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
192.168.2.0/24 dev ens160 proto kernel scope link src 192.168.2.160

# 虚拟机
default via 192.168.3.1 dev enp0s5 proto static
192.168.3.0/24 dev enp0s5 proto kernel scope link src 192.168.3.160
