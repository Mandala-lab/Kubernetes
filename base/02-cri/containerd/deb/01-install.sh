#!/bin/bash

set -e -o posix -o pipefail -x

remove_base() {
  echo "卸载之前安装的docker docker-ce docker-engine docker.io containerd runc"
  sudo apt-get autoremove docker docker-ce docker-engine docker.io containerd runc
}

install_deb_ctr() {
  sudo curl -# -O  https://mirrors.aliyun.com/docker-ce/linux/ubuntu/dists/jammy/pool/stable/amd64/containerd.io_1.7.20-1_amd64.deb
  sudo dpkg -i containerd.io_1.7.20-1_amd64.deb
  sudo containerd --version
}

main() {
  remove_base
  install_deb_ctr
}

main "$@"
