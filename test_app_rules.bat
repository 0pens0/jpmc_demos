@echo off

echo Testing App to App Rules...

echo .
echo Testing unauthorized ingress
kubectl apply -f np-99994-990004-1002-dev-bad-ingress-app-to-app.yaml
pause

echo .
echo Testing unauthorized egress
kubectl apply -f np-99994-990004-1002-dev-bad-egress-app-to-app.yaml
pause

echo .
echo Testing unauthorized prod to dev
kubectl apply -f np-99994-990004-1002-prod-prod-dev.yaml
pause

echo .
echo Testing unauthorized dev to prod
kubectl apply -f np-99994-990004-1002-dev-dev-prod.yaml
pause

echo .
echo Testing unauthorized application module sequencing
kubectl apply -f np-99993-990003-1003-dev-bad-chaining.yaml
pause

echo .
echo Testing unauthorized PCI connectivity
kubectl apply -f np-99994-990004-1002-prod.bad-pci-policy.yaml
echo .
kubectl apply -f np-99992-990002-1002-prod.bad-pci-policy.yaml
pause

echo .
echo Testing approved connectivity
kubectl apply -f np-99994-990004-1002-dev-good-policy.yaml