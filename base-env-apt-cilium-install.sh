#!/usr/bin/bash

set -x

chmod +x ./01-base-env/01-install-all-base-env.sh
chmod +x ./01-base-env/02-install-control-plane-base-env.sh
chmod +x ./02-containerd/01-install.sh
chmod +x ./02-containerd/02-repo.sh
chmod +x ./04-cgroup/01-config.sh
chmod +x ./06-apt-init-components/01-install-control-plane-components.sh

./01-base-env/01-install-all-base-env.sh
./01-base-env/02-install-control-plane-base-env.sh
./02-containerd/01-install.sh
./02-containerd/02-repo.sh
./04-cgroup/01-config.sh
./06-apt-init-components/01-install-control-plane-components.sh
set +x
