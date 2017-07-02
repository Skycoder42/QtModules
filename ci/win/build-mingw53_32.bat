setlocal
set PATH=C:\Qt\Tools\mingw530_32\bin;%PATH%;
set MAKEFLAGS=-j%NUMBER_OF_PROCESSORS%

mkdir build-mingw53_32
cd build-mingw53_32

C:\Qt\5.9\mingw53_32\bin\qmake -r ..\qtjsonserializer.pro
mingw32-make
mingw32-make INSTALL_ROOT=/projects/qjsonserializer/install install
