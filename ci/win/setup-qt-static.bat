@echo on
setlocal EnableDelayedExpansion

:: prepare vcvarsall
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
)
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
)

set tDir=C:\projects\Qt\%QT_VER%\static
mkdir -p %tDir% || exit /B 1
cd C:\projects\Qt\%QT_VER%\Src

:: include extra modules explicitly
for %%m in (%STATIC_EXTRA_MODS%) do (
	echo [submodule "%%m"]>> .gitmodules
	echo 	depends = qtbase>> .gitmodules
	echo 	path = %%m>> .gitmodules
	echo 	url = ../%%m.git>> .gitmodules
	echo 	branch = %QT_VER%>> .gitmodules
	echo 	status = addon>> .gitmodules
	echo 	repoType = inherited>> .gitmodules
)

:: generate skip modules
set skipPart=
for /D %%G in (qt*) do (
	echo "qtbase %STATIC_QT_MODS% %STATIC_EXTRA_MODS%" | findstr /C:"%%G" > nul || (
		set skipPart=-skip %%G !skipPart!
	)
)

call %VC_DIR% amd64 || exit /B 1

:: build qt (shadowed)
mkdir C:\qt-build-tmp
cd C:\qt-build-tmp

call C:\projects\Qt\%QT_VER%\Src\configure -prefix %tDir% -platform win32-msvc -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets %skipPart% || exit /B 1
nmake > nul || exit /B 1
nmake install > nul || exit /B 1
