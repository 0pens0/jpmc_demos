#!/bin/bash

echo "## Testing Naming Rules ##"

echo "## Testing incorrect namespace naming conventions... ##"
echo ""
echo "## Creating namespace test ##"
kubectl create ns test
read -t 5 -p ""

echo ""
echo "## Bad module ##"
kubectl create ns 99992-990002-9002-dev
read -t 5 -p ""

echo ""
echo "## Bad deployment ##"
kubectl create ns 99992-900002-1001-dev
read -t 5 -p ""

echo ""
echo "## Bad module ##"
kubectl create ns 99992-990002-1002x-dev
read -t 5 -p ""

echo ""
echo "## Bad environment ##"
kubectl create ns 99992-990002-1002-dex
read -t 5 -p ""

echo ""
echo "## Bad appID ##"
kubectl create ns 9999x-990002-1002-dev
read -t 5 -p ""

echo ""
echo "## Bad Internet Ingress in DEV ##"
kubectl create ns 99992-990002-1000-dev
read -t 5 -p ""

# kubectl label ns 99992-990002-1002-dev gkp_env=prod --overwrite

# kubectl label ns 99992-990002-1002-dev gkp_xxx=yyy

# Cleanup our zombies
./zombie_ns_delete.sh 99992-990002-9002-dev
./zombie_ns_delete.sh 99992-900002-1001-dev
./zombie_ns_delete.sh 99992-990002-1002x-dev
./zombie_ns_delete.sh 99992-990002-1002-dex
./zombie_ns_delete.sh 9999x-990002-1002-dev
./zombie_ns_delete.sh 99992-990002-1000-dev
./zombie_ns_delete.sh test
