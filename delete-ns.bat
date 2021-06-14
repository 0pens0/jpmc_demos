@ echo off

@FOR /f "usebackq tokens=*" %%i IN (ns-list.txt) DO kubectl delete ns %%i