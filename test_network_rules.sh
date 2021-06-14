#!/bin/bash

echo "## Testing NetworkPolicy Rules ... ##"

echo ""
echo "## Testing blacklisted ports ##"
kubectl apply -f np-99992-990002-1002-dev-bad-ingress-port.yaml

echo ""
kubectl apply -f np-99992-990002-1002-dev-bad-egress-port.yaml
read -t 10 -p ""

echo ""
echo "## Testing non-existent namespace ##"
kubectl apply -f np-99992-990002-1002-dev-bad-egress-ns.yaml
read -t 10 -p ""

echo ""
echo "## Testing excessive access ##"
kubectl apply -f np-99992-990002-1002-dev-bad-ingress-allow-all.yaml

echo ""
kubectl apply -f np-99992-990002-1002-dev-bad-egress-allow-all.yaml

echo ""
kubectl apply -f np-99992-990002-1002-dev-bad-allow-all-ingress-ports.yaml

echo ""
kubectl apply -f np-99992-990002-1002-dev-bad-allow-all-egress-ports.yaml
read -t 10 -p ""

echo ""
echo "## Testing unauthorized perimeter ingress ##"
kubectl apply -f np-99993-990003-1001-prod-bad-perimeter-ingress.yaml
read -t 10 -p ""

echo ""
echo "## Testing dev perimeter ingress ##"
kubectl apply -f np-99993-990003-1001-dev-bad-perimeter-env-ingress.yaml
read -t 10 -p ""
