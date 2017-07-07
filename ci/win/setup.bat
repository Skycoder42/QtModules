:: install qpm
powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe"

:: prepare installer script
set command=echo %QT_VER% | call %~dp0\BatchSubstitute.bat "." ""
for /f "usebackq tokens=*" %%v in ('%command%') do set qtvid=%%v
echo qtVersion = \"%qtvid%\" > %~dp0\qt-installer-script.qs

set command=call :test_include "win32"
for /f "usebackq tokens=*" %%v in ('%command%') do set incres=%%v
echo pfWin32 = \"%incres%\" >> %~dp0\qt-installer-script.qs

set command=call :test_include "winrt"
for /f "usebackq tokens=*" %%v in ('%command%') do set incres=%%v
echo pfWinrt = \"%incres%\" >> %~dp0\qt-installer-script.qs

type %~dp0\qt-installer-modify-script.qs >> %~dp0\qt-installer-script.qs

type %~dp0\qt-installer-script.qs
exit 1

C:\Qt\MaintenanceTool.exe --silentUpdate || exit \B 1
C:\Qt\MaintenanceTool.exe --script ./qt-installer-modify-script.qs --addRepository https://install.skycoder42.de/qtmodules/windows_x86 || exit \B 1

:test_include
echo %EXCLUDE_PLATFORMS% | findstr /C:"%1" > nul && (
	echo false
) || (
	echo true
)
exit /B 0
