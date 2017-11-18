cd install\Qt\%QT_VER%

if "%PLATFORM%" == "static" (
	set PLATFORM=static_win
	rename .\static %PLATFORM%
)

7z a build_%PLATFORM%_%QT_VER%.zip %PLATFORM%
move build_%PLATFORM%_%QT_VER%.zip ..\..\
