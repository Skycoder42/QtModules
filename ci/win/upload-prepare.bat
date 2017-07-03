cd install\Qt\%QT_VER%

if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
	7z a build_win_msvc2017_%QT_VER%.zip msvc2017_64 winrt_x64_msvc2017 winrt_x86_msvc2017 winrt_armv7_msvc2017
)

if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
	7z a build_win_msvc2015_%QT_VER%.zip msvc2015_64 msvc2015
	7z a build_win_mingw_%QT_VER%.zip mingw53_32
)
