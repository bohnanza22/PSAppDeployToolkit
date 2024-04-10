Write-Host 'Testing has started...' -ForegroundColor Cyan
Start-Process -FilePath "C:\Users\WDAGUtilityAccount\$Application\main\Deploy-Application.exe" -Wait
Write-Host 'Installation completed' -ForegroundColor DarkGreen
Write-Host 'you have 60 seconds to verify the installation before it is automatically uninstalled' -ForegroundColor Cyan

$Seconds = 60
$EndTime = [datetime]::UtcNow.AddSeconds($Seconds)

while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
    Write-Progress -Activity 'Waiting for...' -Status testing -SecondsRemaining $TimeRemaining.TotalSeconds
    Start-Sleep 1
}

Start-Process -FilePath "C:\Users\WDAGUtilityAccount\$Application\main\Deploy-Application.exe" -ArgumentList 'Uninstall' -Wait
Write-Host 'test completed' -ForegroundColor DarkGreen
Write-Host 'You can close sandbox now!' -ForegroundColor Cyan
Read-Host -Prompt 'Press any key to continue...'
