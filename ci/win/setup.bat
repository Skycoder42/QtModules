:: install qpm
powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe"

:: prepare installer script
echo qtVersion = "%QT_VER%" > %~dp0\tmp.qs
powershell -File %~dp0\replace.ps1 %~dp0\tmp.qs %~dp0\qt-installer-script.qs

echo image = "%APPVEYOR_BUILD_WORKER_IMAGE%" >> %~dp0\qt-installer-script.qs
call :test_include pfWin32 win32
call :test_include pfWinrt winrt

type %~dp0\qt-installer-modify-script.qs >> %~dp0\qt-installer-script.qs

C:\Qt\MaintenanceTool.exe --silentUpdate || exit \B 1
C:\Qt\MaintenanceTool.exe --script ./qt-installer-modify-script.qs --addRepository https://install.skycoder42.de/qtmodules/windows_x86 || exit \B 1

:: debug
dir C:\Qt\5.9\msvc2017_64\lib\*json*
dir C:\Qt\5.9\msvc2017_64\bin\*rest*

:test_include
echo %EXCLUDE_PLATFORMS% | findstr /C:"%2" > nul && (
	echo %1 = false >> %~dp0\qt-installer-script.qs
) || (
	echo %1 = true >> %~dp0\qt-installer-script.qs
)
exit /B 0
