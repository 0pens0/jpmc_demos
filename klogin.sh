#!/bin/bash
# Automation script to login into vCenter 
 
# See if we got any input
if [ $# -eq 0 ]
then
	# Get the user input
	read "USER?Username: "
	read -s "PASS?Password: "
else
	# We got at least one input - username
        USER=$1

	if [ -z "$2" ]; then
		# Get the password
		read -s "PASS?Password: "
	else
		PASS=$2
	fi
fi

# Check if we got the username 
if [ -z "$USER" ]; then
        echo "Username not provided!"
        exit 1
fi

# Check if we got the password 
if [ -z "$PASS" ]; then
        echo "Password not provided!"
        exit 1
fi

export KUBECTL_VSPHERE_USERNAME=$USER
export KUBECTL_VSPHERE_PASSWORD=$PASS
export KUBECTL_VSPHERE_SERVER="10.193.132.129"

echo "## Logging in as $KUBECTL_VSPHERE_USERNAME ##"
kubectl vsphere login --server http://$KUBECTL_VSPHERE_SERVER/ -u $KUBECTL_VSPHERE_USERNAME@vsphere.local --insecure-skip-tls-verify

# Switch to right context
#kubectl config use-context $KUBECTL_VSPHERE_SERVER
