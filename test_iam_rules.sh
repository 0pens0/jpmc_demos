#!/bin/bash

echo "## Testing IAM Rules... ##"

echo ""
echo "## Testing unauthorized production runtime users and groups ##"
kubectl apply -f dep-99994-990004-1001-prod-iam-fail.yaml

echo ""
echo "## Testing for workload identity ##"
kubectl apply -f dep-99994-990004-1001-prod-iam-identity-fail.yaml
read -t 10 -p ""
