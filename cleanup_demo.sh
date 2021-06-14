#!/bin/bash

# Automation script to delete a namespaces in vCenter and deploy VM's using the VM operator

# Script variables
NS1=99992-990002-1001-dev
NS2=99992-990002-1002-dev
NS3=99992-990002-1003-dev
NS4=99995-990005-1002-dev

echo "## Deleting Ubuntu pods ##"
kubectl delete -f pod-ubuntu.yaml -n $NS1
kubectl delete -f pod-ubuntu.yaml -n $NS2
kubectl delete -f pod-ubuntu.yaml -n $NS4

echo "## Deleting Ubuntu virtual machines ##"
kubectl delete -f vm-ubuntu.yaml -n $NS4
kubectl delete -f vm-ubuntu.yaml -n $NS3

echo "## Deleting Namespaces ##"
kubectl delete ns $NS1
kubectl delete ns $NS2
kubectl delete ns $NS3
kubectl delete ns $NS4

kubectl config delete-context $NS1 
kubectl config delete-context $NS2
kubectl config delete-context $NS3
kubectl config delete-context $NS4

