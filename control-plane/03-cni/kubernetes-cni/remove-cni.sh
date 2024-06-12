#!/bin/bash

set -o posix -o errexit -o pipefail

rm -rf /etc/cni/net.d/10-default.conf

rm -rf ./path/file/opt/cni/bin

set +x
