@echo on
:: before anything else: restore git symlinks
C:\msys64\usr\bin\sh.exe --login %CD%\qtmodules-travis\ci\win\git-setup.sh || exit /B 1

:: install qpm
powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe" || exit /B 1

:: install qpmx
choco install qpmx %EXTRA_PKG% && goto end_qpmx_fallback_install
	echo initiating qpmx fallback install
	powershell -Command "Invoke-WebRequest https://github.com/Skycoder42/qpmx/releases/download/1.6.0/qpmx-1.6.0_msvc2017_64.zip -OutFile C:\projects\qpmx.zip" || exit \B 1
	mkdir C:\projects\qpmx-fallback-install
	7z x C:\projects\qpmx.zip -oC:\projects\qpmx-fallback-install || exit /B 1
	set PATH=C:\projects\qpmx-fallback-install;%PATH%
:end_qpmx_fallback_install
where qpmx && qpmx --version || exit /B 1

:: except winrt -> qtifw
echo %PLATFORM% | findstr /C:"winrt" > nul || (
	set EXTRA_MODULES=qt.tools.ifw.30;%EXTRA_MODULES%
)

:: prepare installer script
echo qtVersion = "%QT_VER%"; > %~dp0\tmp.qs
powershell -File %~dp0\replace.ps1 %~dp0\tmp.qs %~dp0\qt-installer-script.qs
echo prefix = "qt.qt5."; >> %~dp0\qt-installer-script.qs

if "%PLATFORM%" == "msvc2017_64" set PACKAGE=win64_msvc2017_64
if "%PLATFORM%" == "msvc2017" set PACKAGE=win32_msvc2017
if "%PLATFORM%" == "winrt_x64_msvc2017" set PACKAGE=win64_msvc2017_winrt_x64
if "%PLATFORM%" == "winrt_x86_msvc2017" set PACKAGE=win64_msvc2017_winrt_x86
if "%PLATFORM%" == "winrt_armv7_msvc2017" set PACKAGE=win64_msvc2017_winrt_armv7
if "%PLATFORM%" == "msvc2015_64" set PACKAGE=win64_msvc2015_64
if "%PLATFORM%" == "msvc2015" set PACKAGE=win32_msvc2015
if "%PLATFORM%" == "mingw73_64" (
	set PACKAGE=win64_mingw73
	set EXTRA_MODULES=qt.tools.win64_mingw73;%EXTRA_MODULES%
)
if "%PLATFORM%" == "static" set PACKAGE=src

echo platform = "%PACKAGE%"; >> %~dp0\qt-installer-script.qs
echo extraMods = []; >> %~dp0\qt-installer-script.qs
for %%x in (%EXTRA_MODULES%) do (
	echo extraMods.push("%%x"^); >> %~dp0\qt-installer-script.qs
)
type %~dp0\qt-installer-script-base.qs >> %~dp0\qt-installer-script.qs

:: update and install Qt modules
powershell -Command "Invoke-WebRequest https://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe -OutFile C:\projects\qtinst.exe"
C:\projects\qtinst.exe --script %~dp0\qt-installer-script.qs --addTempRepository https://install.skycoder42.de/qtmodules/windows_x86 --verbose > C:\projects\installer.log || (
	type C:\projects\installer.log
	exit \B 1
)

:: build static qt
if "%PLATFORM%" == "static" (
	%~dp0\setup-qt-static.bat || exit /B 1
)

:: mingw make workaround
if "%PLATFORM%" == "mingw73_64" (
	copy C:\projects\Qt\Tools\mingw730_64\bin\mingw32-make.exe C:\projects\Qt\Tools\mingw730_64\bin\make.exe
)
