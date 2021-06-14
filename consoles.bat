@echo off
	
	echo ******************************************************************************************
	echo Starting  consoles
	echo ******************************************************************************************
	start "99992-990002-1001-dev" /D %USERPROFILE%\Documents\Github\demo cmd.exe /t:0F
	start "99992-990002-1002-dev" /D %USERPROFILE%\Documents\Github\demo cmd.exe /t:A0
	start "99992-990002-1003-dev" /D %USERPROFILE%\Documents\Github\demo cmd.exe /t:C0
	rem start "Console 4" /D %USERPROFILE%\Documents\Github\demo cmd.exe /t:1E