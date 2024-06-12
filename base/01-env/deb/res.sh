#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

mv /etc/security/limits.conf{back,}
mv /etc/security/limits.d/20-nproc.conf{back,}
mv /etc/profile{back,}
