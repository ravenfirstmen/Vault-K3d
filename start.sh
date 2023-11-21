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
CA_FILE_NAME="k3s-public-ca"

./gen-certs.sh

k3d cluster create $CLUSTER_NAME \
    --api-port 6443 \
    -p "8200:8200@loadbalancer" -p "8700-8702:30200-30202@agent:0" \
    --agents 1 \
    --k3s-arg '--disable=metrics-server@server:*' \
    --volume "$(pwd)/cert-manager-helm.yaml:/var/lib/rancher/k3s/server/manifests/cert-manager.yaml"

wait_for_pods_to_exist "cert-manager" 120

kubectl apply -f - <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: ca-key-pair
  namespace: cert-manager
data:
  tls.crt: $(base64 -w 0 $(pwd)/${CA_FILE_NAME}.pem)
  tls.key: $(base64 -w 0 $(pwd)/${CA_FILE_NAME}-key.pem)

---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOT

# vault
kubectl apply -f - <<EOT
apiVersion: v1
kind: Namespace
metadata:
  name: vault
---
apiVersion: v1
kind: Secret
metadata:
  name: tls-ca
  namespace: vault
data:
  tls.crt: $(base64 -w 0 $(pwd)/${CA_FILE_NAME}.pem)
EOT

kubectl apply -f vault-helm.yaml 
# kubectl apply -f expose-services.yaml