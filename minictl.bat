@echo off

rem Styra credentials - update often
set cred="Authorization: Bearer OPF5uJbBePqaswRJqJM8b6JCfktx379zFRokBJ-XMv0Z4p0h0F8EgSR7qgK2CfTH4qBrkTtZB-I4mRB-9NwpXHhjbYRYA6M"
set host="https://team1-jpmc.styra.com/v1/systems/fb06aa19f4c440068aa3c5060ba3a2bc/assets/kubectl-all"

rem Point to directory containing policy
set POLICY_DIR=Documents\Github\demo
set POLICY_FILE=%USERPROFILE%\%POLICY_DIR%\gkp.rego

rem Pod CIDR (also updated in calico.yaml)
set POD_CIDR="172.16.250.0/24"

rem Set Host CIDR range
set HOST_CIDR="172.16.251.2/24"

rem Go to policy directory
cd %USERPROFILE%\%POLICY_DIR%\

if /i "%1" == "generate" (
	echo ******************************************************************************************
	echo Generating new TLS keys
	echo ******************************************************************************************
	rem Generage the TLS keys
	del ca.key, ca.srt, ca.srl, server.csr, server.key, server.crt
	rem Create a certificate authority (CA) and certificate/key pair for OPA
	openssl genrsa -out ca.key 2048
	openssl req -x509 -new -nodes -key ca.key -days 100000 -out ca.crt -subj "/CN=admission_ca"
	openssl genrsa -out server.key 2048
	openssl req -new -key server.key -out server.csr -subj "/CN=opa.opa.svc" -config server.conf
	openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 100000 -extensions v3_req -extfile server.conf
	
	echo ******************************************************************************************
	echo Base64 encoding the key
	echo ******************************************************************************************
	rem Base64 encode the caBundle
	del tmp.b64, ca.b64, ca-nonl.b64
	certutil -encode ca.crt tmp.b64 && findstr /v /c:- tmp.b64 > ca.b64
	
	rem Remove newline
	powershell -Command "get-content ca.b64 | Set-Content ca-nonl.b64 -NoNewLine  -Force"
	copy /Y webhook-configuration-noca.yaml webhook-configuration.yaml

	echo ******************************************************************************************
	echo Add to webhook-configuration.yaml
	echo ******************************************************************************************
	rem Add to end of file
	type ca-nonl.b64 >> webhook-configuration.yaml
	del tmp.b64, ca.b64, ca-nonl.b64

) else if /i "%1" == "configure" (
	rem Common settings
	minikube config set cpus 4
	minikube config set memory 16384 
	minikube config set disk-size 40000
	rem minikube config set host-only-cidr 172.17.1.1/24

	rem Manage addons
	rem minikube addons enable ingress
	rem minikube addons enable registry


	if /i "%2" == "hyperv" (
		rem Hyper-V settings
		echo ******************************************************************************************
		echo Configuring %2 vm-driver
		echo ******************************************************************************************
		minikube config set vm-driver %2
		minikube config set hyperv-virtual-switch "Default Switch"

	) else (
		rem VirtualBox settings - default configuration if not specified or incorrect
		echo ******************************************************************************************
		echo Configuring virtualbox vm-driver
		echo ******************************************************************************************
		minikube config set vm-driver virtualbox
		goto :eof
	)
	
) else if /i "%1" == "start" (
	rem Show current settings
	minikube update-check
	minikube config view

	rem Start Kubernetes
	if /i "%2" == "NOCNI" (
		echo ******************************************************************************************
		echo Minikube starting without CNI enabled.
		echo ******************************************************************************************
		minikube start

	) else if /i "%2" == "H-CIDR" (
		echo ******************************************************************************************
		echo Minikube starting with CNI enabled and --host-only-cidr
		echo ******************************************************************************************
		minikube start --cni=calico --host-only-cidr=%HOST_CIDR%
		echo ******************************************************************************************
		echo Wait for pods to start, use following command to display IPAM
		echo 	calicoctl ipam show --show-blocks
		echo .
		echo WARNING - you must install Calico policy for IPAM to function:
		echo 	minictl IPAM
		echo ******************************************************************************************

	) else if /i "%2" == "S-CIDR" (
		echo ******************************************************************************************
		echo Minikube starting with CNI enabled and --service-cluster-ip-range
		echo ******************************************************************************************
		minikube start --cni=calico --service-cluster-ip-range=%POD_CIDR%
		echo ******************************************************************************************
		echo Wait for pods to start, use following command to display IPAM
		echo 	calicoctl ipam show --show-blocks
		echo .
		echo WARNING - you must install Calico policy for IPAM to function:
		echo 	minictl IPAM
		echo ******************************************************************************************

	) else (
		echo ******************************************************************************************
		echo Minikube starting with CNI enabled - Default option
		echo ******************************************************************************************
		minikube start --cni=calico
		set KUBECONFIG=C:\Users\tfari\.kube\CONFIG
		echo ******************************************************************************************
		echo To start second instance
		echo	kubectl config set-context minikubea
		echo	minikube start --network-plugin=cni --cni=calico -p minikubea
		echo .
		echo Wait for pods to start, use following command to display IPAM
		echo 	calicoctl ipam show --show-blocks
		echo .
		echo WARNING - you must install Calico policy for IPAM to function:
		echo 	minictl IPAM
		echo ******************************************************************************************
	)
	pause

	minikube addons list
	kubectl get pods -A
	kubectl cluster-info
	rem Get the Minikube cluster IP address
	setlocal DISABLEDELAYEDEXPANSION		
	@FOR /f "usebackq delims==" %%i IN (`minikube ip`) DO set CLUSTER_IP=%%i
	kubectl get pods -l k8s-app=calico-node -n kube-system
	
) else if /i "%1" == "IPAM" (
	echo ******************************************************************************************
	echo Applying Calico Network IPAM configuration
	echo ******************************************************************************************
	calicoctl apply -f felix.yaml
	calicoctl apply -f ippools.yaml
	calicoctl ipam show --show-blocks
	
) else if /i "%1" == "dashboard" (
	rem Start Kubernetes Dashboard
	minikube dashboard

) else if /i "%1" == "docker" (
	rem Configure Docker
	@FOR /f "tokens=*" %%i IN ('minikube docker-env') DO @%%i
	minikube docker-env
	echo ******************************************************************************************
	echo .
	echo To view running containers:
	echo 	docker ps
	echo .
	echo To view all images:
	echo 	docker images --all
	echo .
	echo To remove an image:
	echo 	docker rmi IMAGE
	echo .
	echo To build an image:
	echo 	docker build -t hello-node:v1 .
	echo .
	echo To run the image:
	echo 	kubectl create deployment hello-node --image=hello-node:v1 --port=8080
	echo	kubectl expose deployment hello-node --type=LoadBalancer
	echo 	minikube service hello-node
	echo 	kubectl set image deployment/hello-node hello-node=hello-node:v2
	echo ******************************************************************************************

) else if /i "%1" == "docker_image" (
	rem Create Ubuntu docker image
	cd ubuntu-with-utils
	echo ******************************************************************************************
	echo .
	echo Building Ubuntu docker image with utilities
	echo .
	docker build -t ubuntu-with-utils:v1 .
	cd ..
	docker images
	echo .
	echo ******************************************************************************************


) else if /i "%1" == "contour" (
	rem Install Contour
	kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
	echo ******************************************************************************************
	echo Installing Contour
	echo .
	echo To view Contour settings:
	echo 	kubectl get -n projectcontour service contour -o wide
	echo 	minikube service -n projectcontour envoy --url
	echo .
	echo ******************************************************************************************

) else if /i "%1" == "contour_test" (
	rem Test Contour

	kubectl describe service envoy -n projectcontour
	kubectl describe service contour -n projectcontour
	kubectl get -n projectcontour service contour -o wide
	minikube service -n projectcontour envoy --url
	kubectl apply -f https://projectcontour.io/examples/kuard-httpproxy.yaml
	kubectl get po,svc,httpproxy -l app=kuard
	rem This grabs the first response
	pause
	@FOR /f "tokens=1" %%i IN ('minikube service -n projectcontour envoy --url') DO (
		set CONTOUR_IP=%%i
		setlocal ENABLEDELAYEDEXPANSION
		curl -H "Host: kuard.local" !CONTOUR_IP!
		setlocal DISABLEDELAYEDEXPANSION		
		exit /b
	)

) else if /i "%1" == "istio" (
	rem Install Istio
	echo ******************************************************************************************
	echo Installing Istio
	echo ******************************************************************************************
	rem minikube addons enable istio-provisioner
	rem minikube addons enable istio --alsologtostderr
	istioctl install --set profile=demo -y
	kubectl label namespace default istio-injection=enabled

) else if /i "%1" == "istio_test" (
	kubectl apply -f C:\Users\tfari\Downloads\istio-1.9.2-win\istio-1.9.2\samples\bookinfo\platform\kube\bookinfo.yaml
	rem kubectl apply -f C:\Users\tfari\Downloads\istio-1.9.2-win\istio-1.9.2\samples\bookinfo\networking\bookinfo-gateway.yaml
	echo ******************************************************************************************
	echo .
	echo	kubectl edit svc productpage <- change to NodePort
	echo 	kubectl get svc
	echo 	http://<minikube ip>:<node port>/productpage
	echo .
	echo 	istioctl analyze
	echo .
	echo ******************************************************************************************

) else if /i "%1" == "jetstack" (
	echo ******************************************************************************************
	echo Installing Jetstack cert manager
	echo ******************************************************************************************
	kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
	kubectl label ns cert-manager openpolicyagent.org/webhook=ignore
	pause
	kubectl apply -f letsencrypt-staging.yaml
	kubectl -n cert-manager get all

) else if /i "%1" == "styra" (
	rem Deploy Styra on minikube
	rem Make sure OPA ignores system namespaces
	kubectl label ns default openpolicyagent.org/webhook=ignore --overwrite
	kubectl label ns kube-system openpolicyagent.org/webhook=ignore --overwrite
	kubectl label ns kube-node-lease openpolicyagent.org/webhook=ignore --overwrite
	kubectl label ns kube-public openpolicyagent.org/webhook=ignore --overwrite
	kubectl label ns kubernetes-dashboard openpolicyagent.org/webhook=ignore --overwrite
	kubectl label ns projectcontour openpolicyagent.org/webhook=ignore  --overwrite
	kubectl label ns istio-system openpolicyagent.org/webhook=ignore  --overwrite
	kubectl label ns kubevirt openpolicyagent.org/webhook=ignore --overwrite
	rem kubectl label ns istio-operator openpolicyagent.org/webhook=ignore
	kubectl get ns -l openpolicyagent.org/webhook=ignore
	curl -H %cred% %host% | kubectl apply -f - --validate=false
	echo ******************************************************************************************
	echo OPA configured to be managed by the Styra control plane
	echo ******************************************************************************************

) else if /i "%1" == "kubevirt" (

	if /i "%2" == "status" (
	
		kubectl label ns kubevirt openpolicyagent.org/webhook=ignore
		kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
		kubectl get all -n kubevirt
		kubectl logs pod/kubevirt-install-manager -n kube-system
		echo ******************************************************************************************
		echo .
		echo To create VM:
		echo 	kubectl apply -f vm.yaml
		echo .
		echo To start the VM after deploying:
		echo 	kubectl-virt start testvm	
		echo .
		echo To connect to console:
		echo 	kubectl-virt console testvm
		echo ******************************************************************************************
		
	) else (

		rem Install KubeVirt
		echo ******************************************************************************************
		echo Enabling kubevirt - extends Kubernetes by adding resource types for VMs
		echo ******************************************************************************************
		minikube addons enable kubevirt
		kubectl label ns kubevirt openpolicyagent.org/webhook=ignore
		echo ******************************************************************************************
		echo 	kubevirt will take several minutes to start
		echo .
		echo Please run to check status: 
		echo 	minictl kubevirt status
		echo .
		echo ******************************************************************************************
	)

) else if /i "%1" == "OPA-API" (
	rem Deploy OPA on minikube as an API server
	setlocal DISABLEDELAYEDEXPANSION		
	set ACM="APISERVER"
	echo ******************************************************************************************
	echo Setting current context to namespace OPA-API
	echo ******************************************************************************************
	kubectl apply -f namespace-opa-api.yaml
	kubectl label ns opa-api openpolicyagent.org/webhook=ignore --overwrite=true
	kubectl config set-context --current --user minikube --cluster minikube --namespace opa-api
	kubectl create configmap acm-policy --namespace opa-api --save-config=false --from-file %POLICY_FILE%
	kubectl apply -f opa-api-server.yaml --namespace opa-api
	@FOR /f "usebackq delims==" %%i IN (`minikube ip`) DO set API_IP=%%i
	set API_PORT=
	if exist port.tmp del port.tmp
	kubectl get service opa-api --output=json --ignore-not-found=true | jq .spec.ports[0].nodePort > port.tmp
	@FOR /f "usebackq delims==" %%i IN (port.tmp) DO set API_PORT=%%i
	if exist port.tmp del port.tmp
	setlocal ENABLEDELAYEDEXPANSION
	echo ******************************************************************************************
	echo OPA configured to run as an API Server on Kubernetes.  
	echo Policy loaded from  %POLICY_FILE%
	echo .
	echo To load policy issue:
	echo 	minictl policy API
	echo .
	echo  Access at: 
	echo 	http://!API_IP!:!API_PORT!/v1/data/admission_control/authz
	echo .
	echo To see logs run the following command:
	echo 	kubectl logs -l app=opa-api -c opa-api -f
	echo ******************************************************************************************
	
) else if /i "%1" == "OPA" (
	rem Deploy OPA on minikube
	kubectl apply -f namespace-opa.yaml
	echo ******************************************************************************************
	echo Setting current context to namespace OPA
	echo ******************************************************************************************
	kubectl config set-context --current --user minikube --cluster minikube --namespace opa
	kubectl create secret tls opa-server --cert=server.crt --key=server.key --namespace opa
	kubectl apply -f admission-controller.yaml --namespace opa
	kubectl label ns kube-system openpolicyagent.org/webhook=ignore --overwrite=true
	kubectl label ns opa openpolicyagent.org/webhook=ignore --overwrite=true
	kubectl apply -f webhook-configuration.yaml --namespace opa
	kubectl create configmap acm-policy --namespace opa --save-config=false --from-file %POLICY_FILE%
	echo ******************************************************************************************
	echo OPA configured to run local. 
	echo Policy loaded from  %POLICY_FILE%
	echo .
	echo To reload policy issue:
	echo 	minictl policy
	echo .
	echo To see logs run the following command:
	echo 	kubectl logs -l app=opa -c opa -f
	echo ******************************************************************************************
	
) else if /i "%1" == "policy" (
	rem Reload OPA policy into minikube
	if /i "%2" == "" (
		echo ******************************************************************************************
		echo Loading policy %POLICY_FILE%
		echo ******************************************************************************************
		kubectl delete configmap acm-policy --namespace opa
		kubectl create configmap acm-policy --namespace opa --save-config=false --from-file %POLICY_FILE%

	) else if /i "%2" == "API" (
		echo ******************************************************************************************
		echo Pushing policy file %POLICY_FILE% to ACM API 
		echo Server %API_IP%:%API_PORT% running on Kubernetes
		echo ******************************************************************************************
		curl -X PUT --data-binary @%POLICY_FILE% --header "Content-Type: application/json" http://%API_IP%:%API_PORT%/v1/policies/admission_control

	) else (
		echo ******************************************************************************************
		echo Loading policy %2.rego
		echo ******************************************************************************************
		kubectl delete configmap %2 --namespace opa
		kubectl create configmap %2 --namespace opa --save-config=false --from-file %2.rego
	)

) else if /i "%1" == "EFK" (
	rem Create the logging namespace
	kubectl apply -f namespace-logging.yaml
	rem Deploy Fluentd configuration as a configmap
	kubectl create configmap fluentd-conf --from-file=fluent.conf --namespace=kube-logging
	rem Deploy EFK on minikube - Elastic Search, Fluentd, Kibana
	kubectl apply -f efk.yaml --namespace kube-logging
	kubectl label ns kube-logging openpolicyagent.org/webhook=ignore --overwrite=true
	echo ******************************************************************************************
	echo Wait for EFK to start, use following command to display NodePort
	echo 	minikube service list
	echo ******************************************************************************************
	pause
	minikube service list | find /i "kibana"

) else if /i "%1" == "gatekeeper" (
	rem Install OPA Gatekeeper 3.0
	echo ******************************************************************************************
	echo Gatekeeper 3.0 - work in progress
	echo ******************************************************************************************
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
	pause
	
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/demo/basic/templates/k8srequiredlabels_template.yaml
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/demo/basic/constraints/all_ns_must_have_gatekeeper.yaml
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/demo/basic/sync.yaml	

) else if /i "%1" == "ns" (
	if /i "%2" == "" (
		echo ******************************************************************************************
		echo Must provide a namespace as the 2nd parameter
		echo ******************************************************************************************
	) else (
		set NAMESPACE=%2
		setlocal ENABLEDELAYEDEXPANSION
		echo ******************************************************************************************
		echo Setting namespace context to !NAMESPACE!
		echo ******************************************************************************************
		kubectl config set-context --current --namespace=!NAMESPACE!
		setlocal DISABLEDELAYEDEXPANSION
	)

) else if /i "%1" == "watch" (

	if /i "%2" == "M" (
		set NAMESPACE=management
	) else if /i "%2" == "CD" (
		set NAMESPACE=99990-900002-1002-dev
	) else if /i "%2" == "CP" (
		set NAMESPACE=99990-900002-1002-prod
	) else if /i "%2" == "PD" (
		set NAMESPACE=99991-900001-900001-dev
	) else if /i "%2" == "PP" (
		set NAMESPACE=99991-900001-900001-prod
	) else if /i "%2" == "WD" (
		set NAMESPACE=99994-990004-1001-dev
	) else if /i "%2" == "WP" (
		set NAMESPACE=99994-990004-1001-prod
	) else if /i "%2" == "AD" (
		set NAMESPACE=99994-990004-1002-dev
	) else if /i "%2" == "AP" (
		set NAMESPACE=99994-990004-1002-prod
	) else if /i "%2" == "DD" (
		set NAMESPACE=99993-990003-1003-dev
	) else if /i "%2" == "DP" (
		set NAMESPACE=99993-990003-1003-prod
	) else if /i "%2" == "" (
		echo ******************************************************************************************
		echo Please provide namespace or M, CD, CP, PD, PP, WD, WP, AD, AP, DD, DP as the 2nd parameter
		echo ******************************************************************************************
		goto :eof
	) else (
		set NAMESPACE=%2
	)
	
	setlocal ENABLEDELAYEDEXPANSION	
	if /i "!NAMESPACE!" == "" (
		echo ******************************************************************************************
		echo Please run minictl watch [namespace] again
		echo ******************************************************************************************
	) else (
		kubectl config set-context --current --namespace=!NAMESPACE!		
		setlocal DISABLEDELAYEDEXPANSION		
		@FOR /f "usebackq delims==" %%i IN (`kubectl get pods -o name`) DO set POD=%%i
		setlocal ENABLEDELAYEDEXPANSION
		if /i "!POD!" == "" (
			echo ******************************************************************************************
			echo Please run minictl watch [namespace] again
			echo ******************************************************************************************
		) else (
			echo ******************************************************************************************
			echo Watching events in pod !POD! in namespace !NAMESPACE!
			echo ******************************************************************************************
			kubectl attach !POD!
		)
	)
	setlocal DISABLEDELAYEDEXPANSION

) else if /i "%1" == "connect" (
	
	if /i "%2" == "M" (
		set NAMESPACE=management
	) else if /i "%2" == "C" (
		set NAMESPACE=99990-900002-1002-dev
	) else if /i "%2" == "P" (
		set NAMESPACE=99991-900001-900001-prod
	) else if /i "%2" == "WD" (
		set NAMESPACE=99994-990004-1001-dev
	) else if /i "%2" == "WP" (
		set NAMESPACE=99994-990004-1001-prod
	) else if /i "%2" == "AD" (
		set NAMESPACE=99994-990004-1002-dev
	) else if /i "%2" == "AP" (
		set NAMESPACE=99994-990004-1002-prod
	) else if /i "%2" == "DD" (
		set NAMESPACE=99993-990003-1003-dev
	) else if /i "%2" == "DP" (
		set NAMESPACE=99993-990003-1003-prod
	) else if /i "%2" == "" (
		echo ******************************************************************************************
		echo Please provide namespace or M, C, P, WD, WP, AD, AP, DD, DP as the 2nd parameter
		echo ******************************************************************************************
		goto :eof
	) else (
		set NAMESPACE=%2
	)

	setlocal ENABLEDELAYEDEXPANSION
	if /i "!NAMESPACE!" == "" (

		if /i "%2" == "" (
			echo ******************************************************************************************
			echo Must provide namespace as 2nd parameter
			echo ******************************************************************************************
			goto :eof
		) else (
			set NAMESPACE=%2		
		)
		
	)	
	kubectl config set-context --current --namespace=!NAMESPACE!
	setlocal DISABLEDELAYEDEXPANSION
	@FOR /f "usebackq delims==" %%i IN (`kubectl get pods -o name`) DO set POD=%%i
	setlocal ENABLEDELAYEDEXPANSION
	if /i "!POD!" == "" (
		echo ******************************************************************************************
		echo Please run minictl connect [namespace] again
		echo ******************************************************************************************
	) else (
		echo ******************************************************************************************
		echo Connecting to pod !POD! in namespace !NAMESPACE!
		echo ******************************************************************************************
		kubectl exec -it !POD! -- /bin/bash
	)
	setlocal DISABLEDELAYEDEXPANSION

) else if /i "%1" == "status" (
	kubectl get pods --all-namespaces
	minikube service list
	kubectl cluster-info

) else if /i "%1" == "deploy" (

	if /i "%3" == "" (
		echo ******************************************************************************************
		echo Deploying to current namespace
		echo ******************************************************************************************
	) else (
		setlocal ENABLEDELAYEDEXPANSION
		set NAMESPACE=%3
		echo ******************************************************************************************
		echo Deploying to namespace !NAMESPACE!
		echo ******************************************************************************************
		kubectl config set-context --current --namespace=!NAMESPACE!
		setlocal DISABLEDELAYEDEXPANSION
	)

	if /i "%2" == "pod" (
		echo ******************************************************************************************
		echo Starting busybox pod...
		echo To resume using pod after disconnect - kubectl attach busybox -c busybox -i -t
		echo ******************************************************************************************
		kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh

	) else if /i "%2" == "image" (
		if /i "%4" == "" (
			echo ******************************************************************************************
			echo Must provide image as 4th parameter
			echo	minictl deploy image [namespace] [image]
			echo ******************************************************************************************
		) else (
			setlocal ENABLEDELAYEDEXPANSION
			echo ******************************************************************************************
			echo Running image %4 in namespace !NAMESPACE!
			echo ******************************************************************************************
			kubectl run %4 --generator=run-pod/v1 -ti --image %4 /bin/sh
			setlocal DISABLEDELAYEDEXPANSION
		)
	) else if /i "%2" == "vm" (
		echo ******************************************************************************************
		echo Configuring VM
		echo ******************************************************************************************
		kubectl apply -f vm.yaml
		pause
		echo ******************************************************************************************
		echo Starting VM...
		echo 	kubectl-virt start testvm
		kubectl-virt start testvm
		echo ******************************************************************************************
		echo Wait for VM to start before accessing console
		echo 	kubectl-virt console testvm
		echo ******************************************************************************************
		pause
		kubectl-virt console testvm

	) else if /i "%2" == "centos" (
		echo ******************************************************************************************
		echo Starting CentOS client...
		echo ******************************************************************************************
		kubectl run -i --tty centos --image=centos --restart=Never -- bash -il

	) else if /i "%2" == "kali" (
		echo ******************************************************************************************
		echo Starting Kali Linux client...
		echo ******************************************************************************************
		kubectl run -i --tty kali --image=kalilinux/kali-rolling --restart=Never -- bash -il

	) else if /i "%2" == "ubuntu" (
		echo ******************************************************************************************
		echo Starting ubuntu Linux client...
		echo ******************************************************************************************
		kubectl run -i --tty ubuntu --image=ubuntu_containerd --restart=Never -- bash -il

	) else (
		echo ******************************************************************************************
		echo Invalid 2nd parameter supplied - must be pod, vm, centos, kali, or zookeeper
		echo ******************************************************************************************
	)


) else if /i "%1" == "demo" (

	rem Create a deployment to run Hello World
	echo ******************************************************************************************
	echo Create a deployment to run Hello World
	echo ******************************************************************************************
	
	rem Create the namespace for the deployment
	kubectl config set-context --current --namespace=89721-a05-dev
	kubectl create -f namespace-89721.yaml
	kubectl get namespaces | find /i "dev"
	pause
	
	rem Create a Deployment that manages a Pod. The Pod runs a Container based on the provided Docker image.
	kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
	kubectl get deployments
	kubectl get pods
	kubectl get events
	kubectl config view
	pause
	
	rem Expose the Pod 
	kubectl expose deployment hello-node --type=LoadBalancer --port=8080
	kubectl get services
	pause
	
	rem The LoadBalancer type makes the Service accessible through the minikube service command
	minikube service hello-node
	
) else if /i "%1" == "cleanup" (
	rem Cleanup
	echo ******************************************************************************************
	echo Misc cleanup routine - back to base Kubernetes Cluster
	echo ******************************************************************************************
	kubectl delete networkpolicies --all -A
	@FOR /f "usebackq delims==" %%i IN (`C:\ProgramData\chocolatey\bin\kubectl.exe get ns -l acm_namespace -o name`) DO kubectl delete %%i

) else if /i "%1" == "remove" (

	if /i "%2" == "OPA" (
		echo ******************************************************************************************
		echo Removing local OPA resources
		echo ******************************************************************************************
		kubectl delete -f webhook-configuration.yaml
		kubectl delete -f admission-controller.yaml
		kubectl delete secret opa-server
		kubectl delete namespace opa

	) else if /i "%2" == "OPA-API" (
		echo ******************************************************************************************
		echo Removing local OPA API resources
		echo ******************************************************************************************
		kubectl delete -f opa-api-server.yaml
		kubectl delete namespace opa-api

	) else if /i "%2" == "styra" (
		rem Remove Styra from minikube
		echo ******************************************************************************************
		echo Removing Styra OPA resources
		echo ******************************************************************************************
		curl -H %cred% %host% | kubectl delete -f -

	) else if /i "%2" == "contour" (
		rem Remove Contour from minikube
		echo ******************************************************************************************
		echo Removing Contour
		echo ******************************************************************************************
		kubectl delete ns projectcontour

	) else if /i "%2" == "EFK" (
		echo ******************************************************************************************
		echo Removing EFK
		echo ******************************************************************************************
		kubectl delete -f efk.yaml --namespace kube-logging
		kubectl delete configmap fluentd-conf --namespace=kube-logging
		kubectl delete -f namespace-logging.yaml

	) else if /i "%2" == "gatekeeper" (
		echo ******************************************************************************************
		echo Removing Gatekeeper 2.0
		echo ******************************************************************************************
		kubectl delete -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

	) else (
		echo ******************************************************************************************
		echo Invalid Parameter %2
		echo .
		echo Must be:
		echo 	OPA-API 		Remove local OPA-API
		echo 	OPA 			Remove local OPA
		echo 	styra			Remove Styra OPA
		echo 	contour			Remove Contour
		echo 	EFK 			Remove EFK configuration
		echo 	gatekeeper		Remove Gatekeeper configuration
		echo .
		echo ******************************************************************************************
		goto :eof
	)

) else if /i "%1" == "stop" (
	rem Stop minikube VM
	echo ******************************************************************************************
	echo Powering off Minikube
	echo ******************************************************************************************
	minikube ssh "sudo poweroff"

) else if /i "%1" == "delete" (
	rem Delete minikube
	echo ******************************************************************************************
	echo Deleting Minikube...
	echo ******************************************************************************************
	set /p command="Enter `delete` to confirm deletion of minikube:  "
	setlocal ENABLEDELAYEDEXPANSION
	minikube !command! -p minikube
	setlocal DISABLEDELAYEDEXPANSION

) else if /i "%1" == "help" (	
	echo ******************************************************************************************
	echo .
	echo Common commands:
	echo .
	echo Get all pods:
	echo 	kubectl get pods -A
	echo .
	echo Connect to specific pod:
	echo 	kubectl exec -it POD -- /bin/bash
	echo 	kubectl exec -it POD --container CONTAINER -- /bin/bash
	echo .
	echo Execute one command in a container:
	echo 	kubectl exec POD ps aux
	echo .
	echo Get the YAML file export for a Kubernetes object
	echo 	kubectl get namespace NAMESPACE -o yaml --export
	echo .
	echo List Events sorted by timestamp
	echo 	kubectl get events --sort-by=.metadata.creationTimestamp
	echo .
	echo ******************************************************************************************
	
) else if /i "%1" == "registry" (
	echo ******************************************************************************************
	echo Map registry to localhost:5000 [work in progress]
	echo ******************************************************************************************
	kubectl create -f kube-registry.yaml
	rem kubectl port-forward --namespace kube-system $(kubectl get po -n kube-system | grep kube-registry-v0 | \awk '{print $1;}') 5000:5000

) else (
	echo ******************************************************************************************
    echo Invalid command supplied [ %1 ] [ %2 ]
	echo Usage:
	echo 	minictl [command] [options]
	echo .
	echo 	generate		Generate the TLS keys
	echo  	configure		Configure Minikube - supply hyperv or virtualbox as 2nd parameter
	echo  	start			Start Minikube - supply NOCNI, H-CIDR, S-CIDR, or EXTRA as 2nd parameter
	echo  	calico 			Start Calico networking
	echo  	IPAM 			Apply Calico IPAM networking configuration
	echo 	OPA-API			Run OPA API Server on minikube 
	echo 	OPA			Setup local OPA
	echo 	policy			Reload policy - defaults to %POLICY_FILE%
	echo  	styra			Setup Styra OPA
	echo  	docker			Configure Docker
	echo  	ns			Set context to namespace provided as 2nd parameter
	echo 	deploy			Deploy resource to namespace - pod, vm, centos, kali
	echo  	connect			Connect to pod in namespace provided as 2nd parameter
	echo  	watch			Watch pod in namespace provided as 2nd parameter
	echo 	EFK 			Deploy EFK on minikube - Elastic Search, Fluentd, Kibana
	echo  	gatekeeper		Install OPA Gatekeeper 2.0
	echo  	kubervirt		Configure Virtual Machine support
	echo  	status			Get Minikube status
	echo  	demo			Deploy Hello World
	echo  	cleanup			Remove added components
	echo  	remove  		Remove components - supplied as 2nd parameter
	echo  	stop			Stop Minikube
	echo  	delete			Delete Minikube
	echo 	help 			Kubernetes command examples
	echo ******************************************************************************************
    goto :eof
  )
)