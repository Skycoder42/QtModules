setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

mkdir build-msvc2017
cd build-msvc2017

C:\Qt\5.9\msvc2017_64\bin\qmake -r ..\qtjsonserializer.pro
nmake all

set PATH=C:\Qt\5.9\msvc2017_64\bin;%CD%\lib;%PATH%;
cd tests\auto
set QT_QPA_PLATFORM=minimal
for /r %%f in (tst_*.exe) do (
	%%f || exit /B 1
)

cd ..\..
nmake INSTALL_ROOT=\projects\qjsonserializer\install install
