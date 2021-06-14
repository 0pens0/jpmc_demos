#!/bin/bash

while IFS= read -r LINE; do
    ./ns-deploy.sh "$LINE"
done < ./ns-list.txt
