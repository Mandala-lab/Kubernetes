#!/bin/bash

set -e -o posix -o pipefail

rm -rf /etc/cni/net.d/10-default.conf

rm -rf ./path/file/opt/cni/bin

set +x
