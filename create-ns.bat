@ echo off

@FOR /f "usebackq tokens=*" %%i IN (ns-list.txt) DO call ns-deploy %%i
