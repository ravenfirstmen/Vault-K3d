#!/bin/bash

wait_for_pods_to_exist() {
  local ns=$1
  local max_wait_secs=$2
  local interval_secs=2
  local start_time
  start_time=$(date +%s)
  while true; do

    current_time=$(date +%s)
    if (( (current_time - start_time) > max_wait_secs )); then
      echo "Waited for pods in namespace [$ns] to exist for $max_wait_secs seconds without luck. Returning with error."
      break
    fi

    if kubectl wait --namespace $ns --for=condition=Ready pods --all --request-timeout "5s"  &> /dev/null; then
      echo "Pods in namespace [$ns] exist."
      break
    else
      echo "Waiting more $interval_secs secs for pods in namespace [$ns] ..."
      sleep $interval_secs
    fi
  done
}

CLUSTER_NAME=vault

./gen-certs.sh

k3d cluster create $CLUSTER_NAME \
    --api-port 6443 \
    --port "8200:8200@loadbalancer" \
    --port "8700-8702:30200-30202@agent:0-2" \
    --agents 3 \
    --k3s-node-label "node-role=worker@agent:0-2" \
    --k3s-arg '--disable=metrics-server@server:*' \
    --volume "$(pwd)/charts:/var/lib/rancher/k3s/server/manifests/charts"

wait_for_pods_to_exist "cert-manager" 120
