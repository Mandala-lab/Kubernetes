#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

# 控制平面安装crictl组件,用于调试
# 如果需要手动上传, 那么请上传二进制文件到/tmp, 文件名为: crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz
# CRICTL_VERSION: 版本, 例如v1.30.0
# ARCH: 架构, 例如, amd64
chmod +x ./debug-tools/crictl/01-install.sh
#./base/03-components/01-crictl/01-install.sh --proxy=y --install --version="v1.32.0"
./debug-tools/crictl/01-install.sh --install --version="v1.32.0"
