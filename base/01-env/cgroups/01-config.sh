#!/bin/sh

set -o posix -o errexit -o pipefail

# 查看cgroup
# https://man7.org/linux/man-pages/man7/cgroups.7.html
# https://kubernetes.io/zh-cn/docs/concepts/architecture/cgroups/#using-cgroupv2
# 获取文件系统类型
filesystem_type=$(stat -fc %T /sys/fs/cgroup)

# 判断文件系统类型是否为 cgroup2fs
# 对于 cgroup v2，输出为`cgroup2fs`。
# 对于 cgroup v1，输出为`tmpfs`。
if [ "$filesystem_type" != "cgroup2fs" ]; then
   # 更新到 cgroup2(Ubuntu20.x)
   sudo grubby \
     --update-kernel=ALL \
     --args="systemd.unified_cgroup_hierarchy=1"
     sudo reboot
fi

# 重启containerd
sudo systemctl restart containerd

set +x
