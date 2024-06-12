#!/bin/bash

set -o posix -o errexit -o pipefail

# Enable shell autocompletion
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
apt install bash-completion
#yum install bash-completion

# 重新加载 shell 并运行 type _init_completion 如果命令成功，则表示已设置，
type _init_completion

# 否则将以下内容添加到 ~/.bashrc 文件中
# source /usr/share/bash-completion/bash_completion

# 启用kubectl自动补全
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-kubectl-autocompletion

echo 'source <(kubectl completion bash)' >>~/.bashrc
# 如果您有 kubectl 的别名，则可以扩展 shell 补全以使用该别名：
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

# 要在 shell 的当前会话中启用 bash 自动完成，请获取 ~/.bashrc 文件
source ~/.bashrc

set +x
