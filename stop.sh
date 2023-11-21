#!/bin/bash

clusterName=vault

if k3d cluster list $clusterName > /dev/null 2>&1; then
    k3d cluster delete $clusterName
    ./clean.sh
fi