#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o errexit -o pipefail -x

chmod +x ./base/03-components/deb/01-install-control-plane-components.sh
./base/03-components/deb/01-install-control-plane-components.sh

