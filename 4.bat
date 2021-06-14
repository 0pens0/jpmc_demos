@echo off
kubectl config set-context --current --namespace=99994-990004-1001-dev
@FOR /f "usebackq delims==" %%i IN (`kubectl get pods -o name`) DO set POD=%%i
setlocal ENABLEDELAYEDEXPANSION
kubectl exec -it !POD! -- /bin/bash
setlocal DISABLEDELAYEDEXPANSION