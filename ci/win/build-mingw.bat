setlocal

for %%* in (.) do set CurrDirName=%%~nx*

set PATH=C:\Qt\Tools\mingw530_32\bin;%PATH%;
set MAKEFLAGS=-j%NUMBER_OF_PROCESSORS%

mkdir build-%PLATFORM%
cd build-%PLATFORM%

C:\Qt\%QT_VER%\%PLATFORM%\bin\qmake -r ..\%PROJECT%.pro || exit /B 1
mingw32-make || exit /B 1
mingw32-make INSTALL_ROOT=/projects/%CurrDirName%/install install

:: build and run test
if NOT "%NO_TESTS%" == "" goto no_tests
	mingw32-make all || exit /B 1

	setlocal
	set PATH=C:\Qt\%QT_VER%\%PLATFORM%\bin;%CD%\lib;%PATH%;
	if "%TEST_DIR%" == "" (
		set TEST_DIR=.\tests\auto
	)
	cd %TEST_DIR%
	set QT_QPA_PLATFORM=minimal
	for /r %%f in (tst_*.exe) do (
		%%f || exit /B 1
	)
	endlocal
:no_tests

:: build documentation
if "%BUILD_DOC%" == "" goto no_doc
	cd \projects\%CurrDirName%
	mkdir build-doc
	cd build-doc

	C:\Qt\%QT_VER%\%PLATFORM%\bin\qmake -r ../doc/doc.pro || exit /B 1
	mingw32-make doxygen || exit /B 1
	mingw32-make INSTALL_ROOT=/projects/%CurrDirName%/install install || exit /B 1
:no_doc
