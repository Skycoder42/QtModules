:: %1 varsall type
:: %2 platform
setlocal

call %~dp0\build-msvc-first.bat %* || exit /B 1

set varsall=%1
set qtplatform=%2

call %VC_DIR% %varsall% || exit /B 1

cd build-%qtplatform%
nmake all || exit /B 1

set PATH=C:\Qt\%QT_VER%\%qtplatform%\bin;%CD%\lib;%PATH%;
cd tests\auto
set QT_QPA_PLATFORM=minimal
for /r %%f in (tst_*.exe) do (
	%%f || exit /B 1
)
