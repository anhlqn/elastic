Get-ChildItem -Path "$PSScriptRoot\Get-*.ps1" | foreach {Start-Process Powershell.exe -ArgumentList "-file $($_.FullName)" -WindowStyle Hidden}
