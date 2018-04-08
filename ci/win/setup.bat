:: make python default
ftype pyfile=C:\Python36-x64\python.exe "%%1"
assoc .py=pyfile

:: install qpm
powershell -Command "Invoke-WebRequest https://storage.googleapis.com/www.qpm.io/download/latest/windows_amd64/qpm.exe -OutFile C:\projects\qpm.exe"

:: install qpmx
choco install qpmx %EXTRA_PKG%

:: except winrt -> qtifw
echo %PLATFORM% | findstr /C:"winrt" > nul || (
	set EXTRA_MODULES=qt.tools.ifw.30;%EXTRA_MODULES%
)

:: prepare installer script
echo qtVersion = "%QT_VER%"; > %~dp0\tmp.qs
powershell -File %~dp0\replace.ps1 %~dp0\tmp.qs %~dp0\qt-installer-script.qs

if "%IS_LTS%" == "true" (
	echo prefix = "qt."; >> %~dp0\qt-installer-script.qs
) else (
	echo prefix = "qt.qt5."; >> %~dp0\qt-installer-script.qs
)

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
type %~dp0\qt-installer-script-base.qs >> %~dp0\qt-installer-script.qs

:: update and install Qt modules
powershell -Command "Invoke-WebRequest https://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe -OutFile C:\projects\qtinst.exe"
C:\projects\qtinst.exe --script %~dp0\qt-installer-script.qs --addTempRepository https://install.skycoder42.de/qtmodules/windows_x86 --verbose > C:\projects\installer.log || (
	type C:\projects\installer.l
	exit \B 1
)

:: build static qt
if "%PLATFORM%" == "static" (
	%~dp0\setup-qt-static.bat || exit \B 1
)

:: mingw32 make workaround
if "%PLATFORM%" == "mingw53_32" (
	copy C:\projects\Qt\Tools\mingw530_32\bin\mingw32-make.exe C:\projects\Qt\Tools\mingw530_32\bin\make.exe
)
