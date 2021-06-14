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
# Replace DB pod by VM
#######################

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

# Revert changes in manifests
sed -i 's/'"$DB_VM"'/db.99993-1003-a01-t4-prod/g' star-app/prod/db-vm/management-ui-prod-db-vm.yaml
sed -i 's/VM/DBd/g' star-app/prod/db-vm/management-ui-prod-db-vm.yaml
sed -i 's/'"$DB_VM"'/db.99993-1003-a01-t4-prod/g' star-app/prod/db-vm/app-prod-db-vm.yaml

