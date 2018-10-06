:: build
setlocal
@echo on

set qtplatform=%PLATFORM%
for %%* in (.) do set CurrDirName=%%~nx*

call %VC_DIR% %VC_VARSALL% || exit /B 1

set PATH=C:\Qt\Tools\QtCreator\bin\;%PATH%

mkdir build-%qtplatform%
cd build-%qtplatform%

C:\projects\Qt\%QT_VER%\%qtplatform%\bin\qmake "CONFIG+=no_auto_lupdate" "QT_PLATFORM=%qtplatform%" %QMAKE_FLAGS% ../ || exit /B 1
jom qmake_all || exit /B 1
jom || exit /B 1
jom lrelease || exit /B 1
jom INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1

:: build and run tests
if NOT "%NO_TESTS%" == "" goto no_tests
if "%MAKE_RUN_TESTS%" == "" goto no_run_tests
	jom all || exit /B 1
	jom /J 1 run-tests || exit /B 1
	goto no_tests
:no_run_tests

:: build and run tests (deprecated)
	jom all || exit /B 1

	setlocal
	set PATH=C:\projects\Qt\%QT_VER%\%qtplatform%\bin;%CD%\lib;%PATH%;
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
	cd \projects\%CurrDirName%\build-%qtplatform%
:no_tests

:: build examples
if "%BUILD_EXAMPLES%" == "" goto no_examples
	jom sub-examples || exit /B 1
	
	cd examples
	jom INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1
	cd ..
:no_examples

:: build documentation
if "%BUILD_DOC%" == "" goto no_doc
	jom doxygen || exit /B 1
	
	cd doc
	jom INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1
	cd ..
:no_doc
