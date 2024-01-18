#!/bin/bash
# 此文件用于配置CRI-O TODO

/etc/crio/crio.conf.d/

[crio.runtime.runtimes.runc]
runtime_path = ""
runtime_type = "oci"
runtime_root = "/run/runc"
