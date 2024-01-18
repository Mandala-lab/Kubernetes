#!/usr/bin/env bash

ifconfig kube-lb0 down
ip link delete kube-lb0
