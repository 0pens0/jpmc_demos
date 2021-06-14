@echo off

rem Automation script to delete a namespaces in vCenter and deploy VM's using the VM operator

rem Script variables
set NS1=99993-990003-1001-dev
set NS2=99993-990003-1002-dev
set NS3=99993-990003-1003-dev
set NS4=99994-990004-1001-dev

echo "## Deleting Ubuntu pods ##"
kubectl delete -f pod-ubuntu-mk.yaml -n %NS1%
kubectl delete -f pod-ubuntu-mk.yaml -n %NS2%
kubectl delete -f pod-ubuntu-mk.yaml -n %NS4%

echo "## Deleting Ubuntu virtual machines ##"
kubectl delete -f vm-ubuntu-mk.yaml -n %NS4%
kubectl delete -f vm-ubuntu-mk.yaml -n %NS3%

echo "## Deleting Namespaces ##"
kubectl delete ns %NS1%
kubectl delete ns %NS2%
kubectl delete ns %NS3%
kubectl delete ns %NS4%
