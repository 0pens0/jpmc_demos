#!/bin/bash

while IFS= read -r LINE; do
    kubectl delete ns "$LINE"
done < ns-list.txt
