setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64_x86

mkdir build-winrt_x86-msvc2017
cd build-winrt_x86-msvc2017

C:\Qt\5.9\winrt_x86_msvc2017\bin\qmake -r ..\qtjsonserializer.pro
nmake
nmake INSTALL_ROOT=\projects\qjsonserializer\install install
