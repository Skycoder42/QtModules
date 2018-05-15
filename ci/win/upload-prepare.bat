cd install\projects\Qt\%QT_VER%

if "%PLATFORM%" == "static" (
	rename static static_win || exit \B 1
	7z a build_static_win_%QT_VER%.zip static_win || exit \B 1
	move build_static_win_%QT_VER%.zip ..\..\..\ || exit \B 1
) else (
	7z a build_%PLATFORM%_%QT_VER%.zip %PLATFORM% || exit \B 1
	move build_%PLATFORM%_%QT_VER%.zip ..\..\..\ || exit \B 1
)

cd ..\..\..\..
