#!/usr/bin/env bash

kubectl get po,svc -n flannel-system -owide
