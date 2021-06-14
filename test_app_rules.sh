#!/bin/bash

echo "## Testing App to App Rules... ##"

echo ""
echo "## Testing unauthorized ingress ##"
kubectl apply -f np-99994-990004-1002-dev-bad-ingress-app-to-app.yaml
read -t 5 -p ""

echo ""
echo "## Testing unauthorized egress ##"
kubectl apply -f np-99994-990004-1002-dev-bad-egress-app-to-app.yaml
read -t 10 -p ""

echo ""
echo "## Testing unauthorized prod to dev ##"
kubectl apply -f np-99994-990004-1002-prod-prod-dev.yaml
read -t 5 -p ""

echo ""
echo "## Testing unauthorized dev to prod ##"
kubectl apply -f np-99994-990004-1002-dev-dev-prod.yaml
read -t 10 -p ""

echo ""
echo "## Testing unauthorized application module sequencing ##"
kubectl apply -f np-99993-990003-1003-dev-bad-chaining.yaml
read -t 10 -p ""

echo ""
echo "## Testing unauthorized PCI connectivity ##"
kubectl apply -f np-99994-990004-1002-prod.bad-pci-policy.yaml
echo ""
kubectl apply -f np-99992-990002-1002-prod.bad-pci-policy.yaml
read -t 10 -p ""

echo ""
echo "## Testing approved connectivity ##"
echo ""
kubectl apply -f np-99994-990004-1002-dev-good-policy.yaml
kubectl describe netpol/99994-990004-1002-dev.good-policy -n 99994-990004-1002-dev
read -t 10 -p ""
