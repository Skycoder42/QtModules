cd install\Qt\%QT_VER%

7z a build_%PLATFORM%_%QT_VER%.zip %PLATFORM%
move build_%PLATFORM%_%QT_VER%.zip ..\..\
