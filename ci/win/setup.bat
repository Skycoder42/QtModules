:: install qpm
powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe"

:: except winrt -> qtifw
echo %PLATFORM% | findstr /C:"winrt" > nul || (
	set EXTRA_MODULES=qt.tools.ifw.20 %EXTRA_MODULES%
)

:: prepare installer script
echo qtVersion = "%QT_VER%" > %~dp0\tmp.qs
powershell -File %~dp0\replace.ps1 %~dp0\tmp.qs %~dp0\qt-installer-script.qs

echo image = "%APPVEYOR_BUILD_WORKER_IMAGE%" >> %~dp0\qt-installer-script.qs
echo platform = "%PLATFORM%"; >> %~dp0\qt-installer-script.qs
echo extraMods = []; >> %~dp0\qt-installer-script.qs
for %%x in (%string%) do (
	echo extraMods.push("%%x"); >> %~dp0\qt-installer-script.qs
)
type %~dp0\qt-installer-modify-script.qs >> %~dp0\qt-installer-script.qs

:: update and install Qt modules
C:\Qt\MaintenanceTool.exe --silentUpdate || exit \B 1
C:\Qt\MaintenanceTool.exe --script %~dp0\qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/windows_x86 || exit \B 1
