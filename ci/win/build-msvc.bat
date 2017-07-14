:: build
@echo on
setlocal

set qtplatform=%PLATFORM%
for %%* in (.) do set CurrDirName=%%~nx*

call %VC_DIR% %VC_VARSALL% || exit /B 1

mkdir build-%qtplatform%
cd build-%qtplatform%

C:\Qt\%QT_VER%\%qtplatform%\bin\qmake -r ..\%PROJECT%.pro || exit /B 1
nmake || exit /B 1
nmake INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1

:: build and run test
if "%NO_TESTS%" == "" (
	nmake all || exit /B 1

	set PATH=C:\Qt\%QT_VER%\%qtplatform%\bin;%CD%\lib;%PATH%;
	if "%TEST_DIR%" == "" (
		set TEST_DIR=.\tests\auto
	)
)

	cd %TEST_DIR%
	set QT_QPA_PLATFORM=minimal
	for /r %%f in (tst_*.exe) do (
		%%f || exit /B 1
	)

echo pre doc
:: build documentation
if NOT "%BUILD_DOC%" == "" (
	echo pre doc real
	cd \projects\%CurrDirName%
	mkdir build-doc
	cd build-doc

	C:\Qt\%QT_VER%\%qtplatform%\bin\qmake -r ../doc/doc.pro || exit /B 1
	nmake doxygen || exit /B 1
	nmake INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1
)
