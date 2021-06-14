@echo off

rem Automation script to create a namespaces in vCenter and deploy VM's using the VM operator

rem Script variables
set NS1=99993-990003-1001-dev
set NS2=99993-990003-1002-dev
set NS3=99993-990003-1003-dev
set NS4=99994-990004-1001-dev

echo "## Create a new Namespaces ##"
kubectl create ns %NS1%
kubectl create ns %NS2%
kubectl create ns %NS3%
kubectl create ns %NS4%

echo "## Deploying Ubuntu pods ##"
kubectl create -f pod-ubuntu-mk.yaml -n %NS1%
kubectl create -f pod-ubuntu-mk.yaml -n %NS2%
kubectl create -f pod-ubuntu-mk.yaml -n %NS4%

echo "## Deploying Ubuntu virtual machines ##"
kubectl create -f vm-ubuntu-mk.yaml -n %NS4%
kubectl create -f vm-ubuntu-mk.yaml -n %NS3%

rem Switch context to the namespace
kubectl config set-context --current --namespace=%NS4%