cd install\projects\Qt\%QT_VER%

if "%PLATFORM%" == "static" (
	rename static static_win || exit \B 1
	7z a %TARGET_NAME%_static_win_%QT_VER%.zip static_win || exit \B 1
	move %TARGET_NAME%_static_win_%QT_VER%.zip ..\..\..\ || exit \B 1
) else (
	7z a %TARGET_NAME%_%PLATFORM%_%QT_VER%.zip %PLATFORM% || exit \B 1
	move %TARGET_NAME%_%PLATFORM%_%QT_VER%.zip ..\..\..\ || exit \B 1
)

cd ..\..\..\..
