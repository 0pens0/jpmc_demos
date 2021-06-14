#!/bin/sh

echo "Creating namespace $1"
kubectl create ns "$1"
./patch_namespace.sh "$1"
