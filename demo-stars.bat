@echo off

if /i "%1" == "update" (

	setlocal DISABLEDELAYEDEXPANSION
	
	@FOR /f "tokens=*" %%i IN ('minikube docker-env') DO @%%i
	
	rem Set context to the Management namespace
	kubectl config set-context --current --namespace=management
	
	rem Get the star-collect container ID
	set CID=
	
	if exist cid.txt del cid.txt

	rem Get the container IDs
	if /i "%2" == "prod" (
		docker ps | find /i "star-collect" | find /i "prod" > cid.txt
	) else (
		docker ps | find /i "star-collect" | find /i "dev" > cid.txt	
	)
	
	@FOR /F %%i IN (cid.txt) DO (
	
		set CID=%%i

		setlocal ENABLEDELAYEDEXPANSION
		if /i "!CID!" == "" (

			echo ******************************************************************************************
			echo Please wait for management namespace to start before re-running:
			echo 	demo-stars update
			echo ******************************************************************************************

		) else (

			if /i "%2" == "prod" (
			
				echo ******************************************************************************************
				echo Patching star-collect container !CID! with %2 view
				echo ******************************************************************************************

				rem Update json config file in container with dev view
				docker cp stars-demo\star\probes-prod.json !CID!:/star/probes.json
			
			) else (
			
				echo ******************************************************************************************
				echo Patching star-collect container !CID! with dev view
				echo ******************************************************************************************

				rem Update json config file in container with dev view
				docker cp stars-demo\star\probes-dev.json !CID!:/star/probes.json
			
			)
			
			rem Update the the probe timeout value
			docker cp stars-demo\star\probe.py !CID!:/star/probe.py
			
			rem Update the star-collect binary
			docker cp stars-demo\star\star-collect !CID!:/star/star-collect

			rem Restart container
			docker container restart !CID!
		)
		
		setlocal DISABLEDELAYEDEXPANSION
	)

	del cid.txt	
	goto :eof

) else if /i "%1" == "debug" (

	echo ******************************************************************************************
	echo 	0. Skipping setup of the namespace consoles
	echo ******************************************************************************************

) else (

	echo ******************************************************************************************
	echo 	0. Setup the namespace consoles
	echo ******************************************************************************************
	rem	start "management [Management]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:0F
	rem	start "client [Client]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:A0
	rem	start "psaas [PSaaS]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:C0

	rem	start "99994-990004-a05-t2-dev [Web]" /D %USERPROFILE%\Documents\OPA\Demo cm	d.exe /t:1E
	rem	start "99994-990004-a05-t3-dev [App]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:B0
	rem	start "99993-990003-a05-t3-dev [DB]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:D0
	
	rem	start "99994-990004-a03-t2-prod [Web]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:1E
	rem	start "99994-990004-a03-t3-prod [App]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:B0
	rem	start "99993-990003-a03-t3-prod [DB]" /D %USERPROFILE%\Documents\OPA\Demo cmd.exe /t:D0

)

echo ******************************************************************************************
echo 	1. Create the web, app, client, and management-ui apps
echo ******************************************************************************************
pause

rem Create the Management applications
kubectl apply -f stars-demo/00-management-ui-dev.yaml
kubectl apply -f stars-demo/00-management-ui-prod.yaml

rem Create the Clients
kubectl apply -f stars-demo/01-client-dev.yaml
kubectl apply -f stars-demo/01-client-prod.yaml

rem Create PSaaS
kubectl apply -f stars-demo/01-psaas-dev.yaml
kubectl apply -f stars-demo/01-psaas-prod.yaml

rem Create the Development application
kubectl apply -f stars-demo/02-web-dev.yaml
kubectl apply -f stars-demo/03-app-dev.yaml
kubectl apply -f stars-demo/04-db-dev.yaml

rem Create the Production application
kubectl apply -f stars-demo/02-web-prod.yaml
kubectl apply -f stars-demo/03-app-prod.yaml
kubectl apply -f stars-demo/04-db-prod.yaml

echo ******************************************************************************************
echo Wait for envionment to finish starting
echo .
kubectl get pods -A
echo .
echo ******************************************************************************************
pause

echo ******************************************************************************************
echo demo-stars-update will execute to patch the stars-collect container - wait for completion
echo ******************************************************************************************
start "management [Management]" /D %USERPROFILE%\Documents\OPA\Demo demo-stars update %1
pause

setlocal DISABLEDELAYEDEXPANSION		
@FOR /f "usebackq delims==" %%i IN (`minikube ip`) DO set CLUSTER_IP=%%i
setlocal ENABLEDELAYEDEXPANSION
if /i "%2" == "prod" (
	set MGMT_UI=http://!CLUSTER_IP!:30003
) else (
	set MGMT_UI=http://!CLUSTER_IP!:30002
)
echo ******************************************************************************************
echo Launching Chrome Browser and connecting to Manaement UI at !MGMT_UI!
echo ******************************************************************************************
start chrome.exe !MGMT_UI!
setlocal DISABLEDELAYEDEXPANSION

echo ******************************************************************************************
echo 	2. Enable namespace isolation with access to core services
echo ******************************************************************************************
pause
kubectl apply -f stars-demo/np-default-deny-cs-dev.yaml
kubectl apply -f stars-demo/np-default-deny-cs-prod.yaml

echo ******************************************************************************************
echo 	3. Allow the Management APP to access the all the services
echo *******************************************************************************************
pause
kubectl apply -f stars-demo/np-allow-mgmt-dev.yaml
kubectl apply -f stars-demo/np-allow-mgmt-prod.yaml

echo ******************************************************************************************
echo 	4a. Apply the app/db policy to allow traffic from the app to the db
echo ******************************************************************************************
pause
kubectl apply -f stars-demo/np-db-policy-dev.yaml
kubectl apply -f stars-demo/np-db-policy-prod.yaml
kubectl apply -f stars-demo/np-app-policy-dev.yaml
kubectl apply -f stars-demo/np-app-policy-prod.yaml

echo ******************************************************************************************
echo 	4b. Apply the web policy to allow traffic from the web to the app
echo ******************************************************************************************
pause
kubectl apply -f stars-demo/np-web-policy-dev.yaml
kubectl apply -f stars-demo/np-web-policy-prod.yaml

echo ******************************************************************************************
echo 	5a. Expose the web service to the PSaaS namespace
echo ******************************************************************************************
pause
kubectl apply -f stars-demo/np-psaas-policy.yaml

echo ******************************************************************************************
echo 	5b. Expose the PSaaS service to the client namespace
echo ******************************************************************************************
pause
kubectl apply -f stars-demo/np-client-policy-dev.yaml
kubectl apply -f stars-demo/np-client-policy-prod.yaml

echo ******************************************************************************************
echo 	6. Clean up the environment
echo ******************************************************************************************
pause
kubectl delete ns 99990-900002-a05-t3-dev 99990-900002-a01-t3-prod 99991-900001-a05-t1-dev 99991-900001-a03-t1-prod 99993-990003-a05-t4-dev 99993-990003-a03-t4-prod 99994-990004-a05-t2-dev 99994-990004-a03-t2-prod 99994-990004-a05-t3-dev 99994-990004-a03-t3-prod 99999-9000-a05-t3-dev 99999-9000-a01-t3-prod 