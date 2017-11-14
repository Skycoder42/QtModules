cd install\Qt\%QT_VER%

set PNAME=%PLATFORM%
if "%PLATFORM%" == "static" (
	set PNAME=%PNAME%_win
)

7z a build_%PNAME%_%QT_VER%.zip %PLATFORM%
move build_%PNAME%_%QT_VER%.zip ..\..\
