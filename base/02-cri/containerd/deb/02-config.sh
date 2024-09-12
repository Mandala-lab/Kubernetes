#!/bin/bash

set -e -o posix -o pipefail -x

generate_ctr_config() {
  sudo mkdir -p /etc/containerd/
  sudo chmod -R 777 /etc/containerd/
  sudo containerd config default > /etc/containerd/config.toml
}

set_config() {
  sudo sed -i "s#SystemdCgroup\ \=\ false#SystemdCgroup\ \=\ true#g" /etc/containerd/config.toml
  sudo cat /etc/containerd/config.toml | grep SystemdCgroup

  sudo sed -i "s#registry.k8s.io/pause:3.8#registry.aliyuncs.com/google_containers/pause:3.10#g" /etc/containerd/config.toml
  sudo cat /etc/containerd/config.toml | grep sandbox_image
}

start_ctr() {
  echo "启动containerd"
  sudo systemctl restart containerd
  sudo systemctl enable containerd
}

check_ctr_path() {
  echo "查看是否启动成功"
  sudo ls /var/run/containerd
}

main() {
  generate_ctr_config
  set_config
  start_ctr
  check_ctr_path
}

main "@"
