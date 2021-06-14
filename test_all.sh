#!/bin/bash

# Cleanup contexts added during namespace creation
./context_cleanup.sh > /dev/null 2>&1

./test_app_rules.sh
./test_iam_rules.sh
./test_naming_rules.sh
./test_network_rules.sh

kubectl apply -f dep-99994-990004-1001-prod-ops-fail.yaml

