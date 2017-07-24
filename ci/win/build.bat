:: builds
set PATH=C:\Python36-x64;%PATH%

:: install QPM dependencies
setlocal
set olddir=%CD%
for /R %%F in (*qpm.json) do (
	echo %%F | findstr /C:"vendor" > nul || (
		cd %%~dpF
		C:\projects\qpm.exe install
		cd %olddir%
	)
)
endlocal

if "%PLATFORM%" == "mingw53_32" (
	call %~dp0\build-mingw.bat || exit /B 1
) else (
	:: prepare vcvarsall
	if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
		set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
	)
	if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
		set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
	)

	:: winrt: skip tests
	echo %PLATFORM% | findstr /C:"winrt" > nul && (
		set NO_TESTS=true
	)

	:: find the varsall parameters
	if "%PLATFORM%" == "msvc2017_64" set VC_VARSALL=amd64
	if "%PLATFORM%" == "winrt_x64_msvc2017" set VC_VARSALL=amd64
	if "%PLATFORM%" == "winrt_x86_msvc2017" set VC_VARSALL=amd64_x86
	if "%PLATFORM%" == "winrt_armv7_msvc2017" set VC_VARSALL=amd64_arm
	if "%PLATFORM%" == "msvc2015_64" set VC_VARSALL=amd64
	if "%PLATFORM%" == "msvc2015" set VC_VARSALL=amd64_x86

	:: build
	call %~dp0\build-msvc.bat || exit /B 1
)
