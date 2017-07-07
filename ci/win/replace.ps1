echo $args[0] $args[1]
Get-Content $args[0] | ForEach-Object {$_ -replace "\.", ""} | Set-Content $args[0]
