:: install qpm
powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe"

:: install qpmx, remove version once published
choco install qpmx --version 1.3.0

:: except winrt -> qtifw
echo %PLATFORM% | findstr /C:"winrt" > nul || (
	set EXTRA_MODULES=qt.tools.ifw.30;%EXTRA_MODULES%
)

:: prepare installer script
echo qtVersion = "%QT_VER%"; > %~dp0\tmp.qs
powershell -File %~dp0\replace.ps1 %~dp0\tmp.qs %~dp0\qt-installer-script.qs

if "%PLATFORM%" == "msvc2017_64" set PACKAGE=win64_msvc2017_64
if "%PLATFORM%" == "winrt_x64_msvc2017" set PACKAGE=win64_msvc2017_winrt_x64
if "%PLATFORM%" == "winrt_x86_msvc2017" set PACKAGE=win64_msvc2017_winrt_x86
if "%PLATFORM%" == "winrt_armv7_msvc2017" set PACKAGE=win64_msvc2017_winrt_armv7
if "%PLATFORM%" == "msvc2015_64" set PACKAGE=win64_msvc2015_64
if "%PLATFORM%" == "msvc2015" set PACKAGE=win32_msvc2015
if "%PLATFORM%" == "mingw53_32" (
	set PACKAGE=win32_mingw53
	set EXTRA_MODULES=qt.tools.win32_mingw530;%EXTRA_MODULES%
)
if "%PLATFORM%" == "static" set PACKAGE=src

echo platform = "%PACKAGE%"; >> %~dp0\qt-installer-script.qs
echo extraMods = []; >> %~dp0\qt-installer-script.qs
for %%x in (%EXTRA_MODULES%) do (
	echo extraMods.push("%%x"^); >> %~dp0\qt-installer-script.qs
)
type %~dp0\qt-installer-modify-script.qs >> %~dp0\qt-installer-script.qs

:: update and install Qt modules
C:\Qt\MaintenanceTool.exe --silentUpdate || exit \B 1
C:\Qt\MaintenanceTool.exe --script %~dp0\qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/windows_x86 || (
	find /c "no_modules_changed" C:\Qt\InstallationLog.txt > nul || (
		type C:\Qt\InstallationLog.txt
		exit \B 1
	)
)

:: build static qt
if "%PLATFORM%" == "static" (
	%~dp0\setup-qt-static.bat || exit \B 1
)
