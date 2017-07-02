setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64

mkdir build-msvc2015
cd build-msvc2015

C:\Qt\5.9\msvc2015_64\bin\qmake -r ..\qtjsonserializer.pro
nmake
nmake INSTALL_ROOT=\projects\qjsonserializer\install install
