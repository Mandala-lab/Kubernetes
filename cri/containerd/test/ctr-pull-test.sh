#!/bin/bash

sudo ctr i pull docker.io/library/nginx:alpine
sudo ctr images ls # 查看镜像
sudo ctr c create --net-host docker.io/library/nginx:alpine nginx # 创建容器
sudo ctr task start -d nginx # 启动容器，正常说明containerd没啥问题
sudo ctr containers ls # 查看容器
sudo ctr tasks kill -s SIGKILL nginx # 终止容器
sudo ctr containers rm nginx # 删除容器
