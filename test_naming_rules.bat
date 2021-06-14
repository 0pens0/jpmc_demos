@echo on
cls

echo Testing Naming Rules

kubectl create ns test

kubectl create ns 99990-900001-9002-dev
pause

kubectl create ns 99990-900002-1001-dev

kubectl create ns 99990-900002-9002x-dev
pause

kubectl create ns 99990-900002-9002-dex

kubectl create ns 99995-900002-9002-dev
pause

kubectl create ns 99990-abc-9002-dev

kubectl create ns 99992-990002-1000-dev
pause

kubectl label ns 99990-900002-9002-dev gkp_env=prod --overwrite

kubectl label ns 99990-900002-9002-dev gkp_xxx=yyy