#!/bin/bash

# Automation script to create a namespaces in vCenter and deploy VM's using the VM operator
# Script variables
NS1=99992-990002-1001-dev
NS2=99992-990002-1002-dev
NS3=99992-990002-1003-dev
NS4=99995-990005-1002-dev

clear

echo "####################################################################################################################"
echo "## This demonstration will showcase the coexistence of containers and VMs composed through the Kubernetes API: "
echo "##    "
echo "##    1. Create 4 namespaces through the K8S API: " 
echo "##       $NS1, $NS2, $NS3, $NS4"
echo "##    "
echo "##       Namespaces have the following tuple format: <application>-<deployment>-<app module>-<environment>"
echo "##       - Labels and annotations will be added to each namespace based on CMDB data"
echo "##       - Namespaces will be created in vCenter and logical segments in NSX-T"
echo "##    "
echo "##    2. Deploy containers and virtuals machines through the K8S API"
echo "##    "
echo "##    3. Apply network policy to restrict traffic between namespaces"
echo "##    "
echo "##       Demonstrating Layer 3/4 policy using NSX-T - also will support Service Mesh"
echo "##    "
echo "####################################################################################################################"
read -p ""

echo "## Create new Namespaces ##"
echo " "
echo "kubectl create ns $NS1"
kubectl create ns $NS1
echo " "
echo "kubectl create ns $NS2"
kubectl create ns $NS2
echo " "
echo "kubectl create ns $NS3"
kubectl create ns $NS3
echo " "
echo "kubectl create ns $NS4"
kubectl create ns $NS4

# Patch the namespaces
./patch_namespace.sh $NS1 > /dev/null 2>&1
./patch_namespace.sh $NS2 > /dev/null 2>&1
./patch_namespace.sh $NS3 > /dev/null 2>&1
./patch_namespace.sh $NS4 > /dev/null 2>&1
read -p ""

clear
echo "####################################################################################################################"
echo " Namespaces will have a set of labels and annotations added to control future behaviour: "
echo "  "
read -p ""
echo "kubectl describe ns $NS1"
kubectl describe ns $NS1
read -p ""

clear
echo "## Deploying Ubuntu pods ##"
echo " "
cat pod-ubuntu.yaml
echo " "
read -p ""
echo "kubectl create -f pod-ubuntu.yaml -n $NS1"
kubectl create -f pod-ubuntu.yaml -n $NS1
echo " "
echo "kubectl create -f pod-ubuntu.yaml -n $NS2"
kubectl create -f pod-ubuntu.yaml -n $NS2
echo " "
echo "kubectl create -f pod-ubuntu.yaml -n $NS4"
kubectl create -f pod-ubuntu.yaml -n $NS4
read -p ""

clear
echo " "
echo "## Deploying Ubuntu virtual machines ##"
echo " "
echo "kubectl get virtualmachineclass"
kubectl get virtualmachineclass
read -p ""
cat vm-ubuntu.yaml
echo " "
read -p ""
echo "kubectl create -f vm-ubuntu.yaml -n $NS3"
kubectl create -f vm-ubuntu.yaml -n $NS3
echo " "
echo "kubectl create -f vm-ubuntu.yaml -n $NS4"
kubectl create -f vm-ubuntu.yaml -n $NS4
read -p ""
echo " "
echo "kubectl get vm -A"
kubectl get vm -A
read -p ""

clear
echo "## Applying NetworkPolicy to each namespace ##"
echo " "
cat np-demo.yaml | more
echo " "
read -p ""
echo " "
echo "kubectl apply -f np-demo.yaml"
kubectl apply -f np-demo.yaml
read -p ""

echo " "
echo "## See applied NetworkPolicy ##"
echo " "
echo "kubectl describe netpol -n $NS1"
kubectl describe netpol -n $NS1
read -t 10 -p ""
echo " "
echo "kubectl describe netpol -n $NS2"
kubectl describe netpol -n $NS2
read -t 10 -p ""
echo " "
echo "kubectl describe netpol -n $NS3"
kubectl describe netpol -n $NS3
read -t 10 -p ""
echo " "
echo "kubectl describe netpol -n $NS4"
kubectl describe netpol -n $NS4
read -t 10 -p ""
