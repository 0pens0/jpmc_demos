@echo off
kubectl config set-context --current --namespace=99993-990003-1002-dev
@FOR /f "usebackq delims==" %%i IN (`kubectl get pods -o name`) DO set POD=%%i
setlocal ENABLEDELAYEDEXPANSION
kubectl exec -it !POD! -- /bin/bash
setlocal DISABLEDELAYEDEXPANSION