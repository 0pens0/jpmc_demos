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

p "### Default network policy to allow DNS queries ###"
cat star-app/prod/default-network-policies/np-allow-dns-prod.yaml | head -15
p ""
PROMPT_TIMEOUT=0
wait

p "### Default network policy to allow MGMT UI ###"
cat star-app/prod/default-network-policies/np-allow-ui-prod.yaml | head -15
p ""
PROMPT_TIMEOUT=0
wait

p "### Apply DEV default network policies ###"
pe "kubectl apply -f star-app/prod/default-network-policies/"
p ""
p "Press ENTER to continue..."
p ""
PROMPT_TIMEOUT=0
wait

p "### Get DEV MGMT-UI ###"
pe "kubectl get svc -n management"
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

# p "### Apply DEV incorrect network policy ###"
# cat star-app/enforcement-validation/np-tier-jump.yaml
# PROMPT_TIMEOUT=0
# wait
# pe "kubectl apply -f star-app/enforcement-validation/np-tier-jump.yaml"
# p ""


