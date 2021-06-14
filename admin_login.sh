#!/bin/bash
# Automation script to login into vCenter 

export KUBECTL_VSPHERE_USERNAME=administrator
export KUBECTL_VSPHERE_PASSWORD=YY#eXpa7EJ.P8oEz6=CV
export KUBECTL_VSPHERE_SERVER="10.193.132.129"

. ./klogin.sh $KUBECTL_VSPHERE_USERNAME $KUBECTL_VSPHERE_PASSWORD
#kubectl vsphere login --server http://$KUBECTL_VSPHERE_SERVER/ -u $KUBECTL_VSPHERE_USERNAME@vsphere.local --insecure-skip-tls-verify

# Switch to right context
#kubectl config use-context $KUBECTL_VSPHERE_SERVER
