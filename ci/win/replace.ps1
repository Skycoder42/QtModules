echo %~dp0\qt-installer-script.qs
Get-Content %~dp0\qt-installer-script.qs | ForEach-Object {$_ -replace "\.", ""} | Set-Content %~dp0\qt-installer-script.qs
