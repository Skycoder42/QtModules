:: build
setlocal

set qtplatform=%PLATFORM%
for %%* in (.) do set CurrDirName=%%~nx*

call %VC_DIR% %VC_VARSALL% || exit /B 1

mkdir build-%qtplatform%
cd build-%qtplatform%

C:\projects\Qt\%QT_VER%\%qtplatform%\bin\qmake ../ || exit /B 1
nmake qmake_all || exit /B 1
nmake || exit /B 1
nmake lrelease || exit /B 1
nmake INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1

:: build and run test
if NOT "%NO_TESTS%" == "" goto no_tests
	nmake all || exit /B 1

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
	nmake sub-examples || exit /B 1
	
	cd examples
	nmake INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1
	cd ..
:no_examples

:: build documentation
if "%BUILD_DOC%" == "" goto no_doc
	nmake doxygen || exit /B 1
	
	cd doc
	nmake INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1
	cd ..
:no_doc
