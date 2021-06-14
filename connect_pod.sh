#!/bin/bash
# Automation script to connect to a pod
 
# See if we got any input
if [ $# -eq 0 ]
then
	# Get the user input
	read "POD?Pod: "
	read "NAMESPACE?Namespace: "
else
	POD=$1
	NAMESPACE=$2
fi

# Check if we got the pod 
if [ -z "$POD" ]; then
        echo "Pod not provided!"
        exit 1
fi

# Check if we got the namespace 
if [ -z "$NAMESPACE" ]; then
        echo "Namespace not provided!"
        exit 1
fi


echo "## Connecting to pod $POD in namespace $NAMESPACE ##"
kubectl exec -it -n $NAMESPACE $POD -- sh
