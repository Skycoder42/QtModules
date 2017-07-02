setlocal

set platform=mingw53_32

set PATH=C:\Qt\Tools\mingw530_32\bin;%PATH%;
set MAKEFLAGS=-j%NUMBER_OF_PROCESSORS%

mkdir build-%platform%
cd build-%platform%

C:\Qt\%QT_VER%\%platform%\bin\qmake -r ..\%PROJECT%.pro || exit /B 1
mingw32-make || exit /B 1

for %%* in (.) do set CurrDirName=%%~nx*
mingw32-make INSTALL_ROOT=\projects\%CurrDirName%\install install || exit /B 1
