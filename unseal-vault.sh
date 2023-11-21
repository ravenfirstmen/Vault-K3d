#!/bin/bash

# kubectl apply -f expose-services.yaml

VAULT_PORTS=("8700" "8701" "8702")

UNSEAL_INFO_FILE="unseal-info.json"

function unseal_vault {

  local unseal_info
	
  if [ ! -f $UNSEAL_INFO_FILE ];
  then
    vault operator init -format=json > $UNSEAL_INFO_FILE
  fi
  
  unseal_info=$(cat $UNSEAL_INFO_FILE)
  unseal_threshold=$(echo $unseal_info | jq -r '.unseal_threshold')
  
  echo $unseal_info | jq -r '.unseal_keys_b64[]' | head -n $unseal_threshold | while read key;
  do 
    vault operator unseal $key
  done

  echo "Vault unsealed.... the unseal info IS in $UNSEAL_INFO_FILE file"  
} 

for vault_port in ${VAULT_PORTS[@]}; do

    export VAULT_ADDR=https://localhost:${vault_port}
    #export VAULT_SKIP_VERIFY="true"
    export VAULT_CACERT=k3s-public-ca.pem

    vault status 1>/dev/null

    # TODO: change to /v1/sys/health?!
    # 200 if initialized, unsealed, and active
    # 429 if unsealed and standby
    # 472 if disaster recovery mode replication secondary and active
    # 473 if performance standby
    # 501 if not initialized
    # 503 if sealed

    case $? in

    "0")
        echo "Already unsealed! move on... BTW: the unseal info SHOULD be in $UNSEAL_INFO_FILE file"
        ;;

    "1")
        echo "Some error in the vault instance... exiting unseal process!"
        exit 1
        ;;

    "2")   
        unseal_vault
        echo "Espera um pouco pela replicacao (10s)..."
        sleep 10s    
        ;;

    *)
        echo "What?! (response was: $?)"
        ;;
    esac

done