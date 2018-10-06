setlocal
@echo off

for %%* in (.) do set CurrDirName=%%~nx*

set PATH=C:\projects\Qt\Tools\mingw530_32\bin;%PATH%;
set MAKEFLAGS=-j%NUMBER_OF_PROCESSORS%

mkdir build-%PLATFORM%
cd build-%PLATFORM%

C:\projects\Qt\%QT_VER%\%PLATFORM%\bin\qmake "CONFIG+=no_auto_lupdate" "QT_PLATFORM=%PLATFORM%" %QMAKE_FLAGS% ../ || exit /B 1
mingw32-make qmake_all || exit /B 1
mingw32-make || exit /B 1
mingw32-make lrelease || exit /B 1
mingw32-make INSTALL_ROOT=/projects/%CurrDirName%/install install || exit /B 1

:: build and run tests
if NOT "%NO_TESTS%" == "" goto no_tests
if "%MAKE_RUN_TESTS%" == "" goto no_run_tests
	mingw32-make all || exit /B 1
	mingw32-make -j1 run-tests || exit /B 1
	goto no_tests
:no_run_tests

:: build and run tests (deprecated)
	mingw32-make all || exit /B 1

	setlocal
	set PATH=C:\projects\Qt\%QT_VER%\%PLATFORM%\bin;%CD%\lib;%PATH%;
	set QT_PLUGIN_PATH=%CD%\plugins;%QT_PLUGIN_PATH%;
	if "%TEST_DIR%" == "" (
		set TEST_DIR=.\tests\auto
	)
	cd %TEST_DIR%
	set QT_QPA_PLATFORM=minimal
	for /r %%f in (tst_*.exe) do (
		start /w call %%f ^> %CD%/test.log ^|^| echo FAIL ^> fail ^& exit || exit /B 1
		type test.log
		if exist fail exit /B 1
	)
	endlocal
	cd \projects\%CurrDirName%\build-%PLATFORM%
:no_tests

:: build examples
if "%BUILD_EXAMPLES%" == "" goto no_examples
	mingw32-make sub-examples || exit /B 1
	
	cd examples
	mingw32-make INSTALL_ROOT=/projects/%CurrDirName%/install install || exit /B 1
	cd ..
:no_examples

:: build documentation
if "%BUILD_DOC%" == "" goto no_doc
	mingw32-make doxygen || exit /B 1
	
	cd doc
	mingw32-make INSTALL_ROOT=/projects/%CurrDirName%/install install || exit /B 1
	cd ..
:no_doc
