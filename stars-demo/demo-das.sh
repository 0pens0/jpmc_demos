#!/bin/bash

########################
# include the magic
########################
. ./demo-magic/demo-magic.sh

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# hide the evidence
clear

########################################################################
# DEMO
########################################################################

#######################
# Integrate OPA
#######################

p "### Label namespaces to bypass OPA ###"
p ""
PROMPT_TIMEOUT=1
wait

p "### Deploy OPA as admission controller ###"
p "curl -H 'Authorization: Bearer <TOKEN>' 'https://team1-jpmc.styra.com/v1/systems/bb800c63164c40e2a29fe707054ed3a8/assets/kubectl-all' | kubectl apply -f -"
p ""
PROMPT_TIMEOUT=1
wait

#######################
# Deploy star apps
#######################

p "### Deploy DEV apps ###"
pe "kubectl apply -f star-app/prod/apps/"
pe "kubectl get pods -A -w | grep -v system"
p ""
PROMPT_TIMEOUT=0
wait

# p "### Deploy PROD apps ###"
# pe "kubectl apply -f star-app/prod/apps/"
# p ""
# pe "watch kubectl get pods -A |grep -v system"
# p "Press ENTER to continue..."
# p ""
# PROMPT_TIMEOUT=0
# wait

#######################
# Default network policies
#######################

p "### Default network policy to allow MGMT UI ###"
cat star-app/prod/default-network-policies/np-allow-ui-prod.yaml
p ""
PROMPT_TIMEOUT=0
wait

# p "### Default network policy to allow DNS queries ###"
# cat star-app/prod/default-network-policies/np-allow-dns-prod.yaml
# p ""
# PROMPT_TIMEOUT=0
# wait

p "### Apply DEV default network policies ###"
pe "kubectl apply -f star-app/prod/default-network-policies/"
p ""
p "Press ENTER to continue..."
p ""
PROMPT_TIMEOUT=0
wait

# p "### Apply PROD default network policies ###"
# pe "kubectl apply -f star-app/prod/default-network-policies/"
# p ""
# p "Press ENTER to continue..."
# p ""
# PROMPT_TIMEOUT=0
# wait

#######################
# Network policies
#######################

p "### Network policy to allow client -> pssas communication - Client side ###"
cat star-app/prod/network-policies/np-client-prod.yaml
p ""
PROMPT_TIMEOUT=0
wait

p "### Network policy to allow client -> pssas communication - PSAAS side ###"
cat star-app/prod/network-policies/np-psaas-prod.yaml
p ""
PROMPT_TIMEOUT=0
wait

p "### Apply DEV network policies ###"
pe "kubectl apply -f star-app/prod/network-policies/"
p ""
p "Press ENTER to continue..."
p ""
PROMPT_TIMEOUT=0
wait

# p "### Apply PROD network policies ###"
# pe "kubectl apply -f star-app/prod/network-policies/"
# p ""
# p "Press ENTER to continue..."
# p ""
# PROMPT_TIMEOUT=0
# wait

p "### Apply DEV incorrect network policy ###"
cat star-app/enforcement-validation/np-tier-jump.yaml
PROMPT_TIMEOUT=0
wait
pe "kubectl apply -f star-app/enforcement-validation/np-tier-jump.yaml"
p ""
p "Press ENTER to continue..."
p ""
PROMPT_TIMEOUT=0
wait

#######################
# Replace DB pod by VM
#######################
while true; do
    read -p 'Do you want to replace DB pod by a VM? [Y/n]' yn
    case $yn in
        [Nn]* ) 
            p ""
            p "Thanks for watching! :)"
            p ""
            PROMPT_TIMEOUT=1
            wait
            exit
        ;;
        [Yy]* )
            read -p 'Please enter VM IP address: ' DB_VM

            pe "kubectl delete replicationcontroller db -n 99993-1003-a01-t4-prod"

            pe "sed -i 's/db.99993-1003-a01-t4-prod/'"$DB_VM"'/g' star-app/prod/db-vm/management-ui-prod-db-vm.yaml"
            sed -i 's/DBd/VM/g' star-app/prod/db-vm/management-ui-prod-db-vm.yaml
            pe "kubectl apply -f star-app/prod/db-vm/management-ui-prod-db-vm.yaml"
            MGMT_POD=$(kubectl get pods -n management | awk {'print $1'} | grep -v NAME)
            pe "kubectl delete pod $MGMT_POD -n management"

            pe "sed -i 's/db.99993-1003-a01-t4-prod/'"$DB_VM"'/g' star-app/prod/db-vm/app-prod-db-vm.yaml"
            pe "kubectl apply -f star-app/prod/db-vm/app-prod-db-vm.yaml"
            APP_POD=$(kubectl get pods -n 99994-1002-a01-t3-prod | awk {'print $1'} | grep -v NAME)
            pe "kubectl delete pod $APP_POD -n 99994-1002-a01-t3-prod"

            p ""
            p "Press ENTER to continue..."
            p ""
            PROMPT_TIMEOUT=0
            wait

            # Revert changes in manifests
            sed -i 's/'"$DB_VM"'/db.99993-1003-a01-t4-prod/g' star-app/prod/db-vm/management-ui-prod-db-vm.yaml
            sed -i 's/VM/DBd/g' star-app/prod/db-vm/management-ui-prod-db-vm.yaml
            sed -i 's/'"$DB_VM"'/db.99993-1003-a01-t4-prod/g' star-app/prod/db-vm/app-prod-db-vm.yaml

            p ""
            p "Thanks for watching! :)"
            p ""
            PROMPT_TIMEOUT=1
            wait

            exit
        ;;
        * ) echo "Please answer yes or no.";;
    esac
done

p ""
p "Thanks for watching! :)"
p ""
PROMPT_TIMEOUT=1
wait




