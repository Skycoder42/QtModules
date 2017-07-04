:: builds

if "%TEST_DIR%" == "" (
	set TEST_DIR=.\tests\auto
)

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

if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"

	echo %EXCLUDE_PLATFORMS% | findstr /C:"win32" > nul || (
		if "%NO_TESTS%" == "" (
			call %~dp0\build-msvc-all.bat amd64 msvc2017_64 || exit /B 1
		) else (
			call %~dp0\build-msvc-first.bat amd64 msvc2017_64 || exit /B 1
		)
	)

	echo %EXCLUDE_PLATFORMS% | findstr /C:"winrt" > nul || (
		call %~dp0\build-msvc-first.bat amd64 winrt_x64_msvc2017 || exit /B 1
		call %~dp0\build-msvc-first.bat amd64_x86 winrt_x86_msvc2017 || exit /B 1
		call %~dp0\build-msvc-first.bat amd64_arm winrt_armv7_msvc2017 || exit /B 1
	)
)

if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" (
	set VC_DIR="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"

	echo %EXCLUDE_PLATFORMS% | findstr /C:"win32" > nul || (
		if "%NO_TESTS%" == "" (
			call %~dp0\build-msvc-all.bat amd64 msvc2015_64 || exit /B 1
			call %~dp0\build-msvc-all.bat amd64_x86 msvc2015 || exit /B 1
		) else (
			call %~dp0\build-msvc-first.bat amd64 msvc2015_64 || exit /B 1
			call %~dp0\build-msvc-first.bat amd64_x86 msvc2015 || exit /B 1
		)
		call %~dp0\build-mingw.bat || exit /B 1
	)
)
