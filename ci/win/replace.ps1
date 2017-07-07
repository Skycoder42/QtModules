Get-Content $args[0] | ForEach-Object {$_ -replace "\.", ""} | Set-Content $args[1]
