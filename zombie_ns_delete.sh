#!/bin/bash
# Automation script to delete zombie namespaces

DCLI_VSPHERE_SERVER=10.193.132.10

dcli +skip-server-verification +server $DCLI_VSPHERE_SERVER +username $KUBECTL_VSPHERE_USERNAME@vsphere.local +password $KUBECTL_VSPHERE_PASSWORD com vmware vcenter namespaces instances delete --namespace $1 
