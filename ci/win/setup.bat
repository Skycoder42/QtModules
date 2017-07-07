@echo on
:: install qpm
:: powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe"

:: prepare installer script
echo qtVersion = ""%QT_VER%"" | call %~dp0\BatchSubstitute.bat "." "" > %~dp0\qt-installer-script.qs

echo pfWin32 = 
call :test_include "win32"

echo pfWinrt = 
call :test_include "winrt"

type %~dp0\qt-installer-modify-script.qs >> %~dp0\qt-installer-script.qs

type %~dp0\qt-installer-script.qs
exit 1

C:\Qt\MaintenanceTool.exe --silentUpdate || exit \B 1
C:\Qt\MaintenanceTool.exe --script ./qt-installer-modify-script.qs --addRepository https://install.skycoder42.de/qtmodules/windows_x86 || exit \B 1

:test_include
echo %EXCLUDE_PLATFORMS% | findstr /C:"%1" > nul && (
	echo "false" >> %~dp0\qt-installer-script.qs
) || (
	echo "true" >> %~dp0\qt-installer-script.qs
)
exit /B 0
