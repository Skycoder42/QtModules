@echo on

:: prepare vcvarsall
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
)
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
)
	
set tDir=C:\Qt\%QT_VER%\static
mkdir -p %tDir% || exit /B 1

cd C:\Qt\%QT_VER%\Src
for /D %%G in (*) do (
	echo "qtbase %STATIC_QT_MODS%" | findstr /C:"%%G" > nul || (
		set skipPart=-skip %%G %skipPart%
	)
)

call %VC_DIR% amd64 || exit /B 1

echo before config
.\configure -prefix %tDir% -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets %skipPart%
echo before make
nmake
echo before make install
nmake install

cd ../static
dir
