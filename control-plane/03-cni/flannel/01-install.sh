#!/usr/bin/env bash

wget -t 2 -T 240 -N -S -progress=dot https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
