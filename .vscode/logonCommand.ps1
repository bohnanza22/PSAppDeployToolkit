#LogonCommand.ps1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$Application,
    [int]$VerificationTime = 120  # Optional parameter for verification time
)

$deployPath = "C:\Users\WDAGUtilityAccount\Desktop\$Application"

if (Test-Path -Path "$deployPath\Deploy-Application.exe") {
    Write-Host 'Testing has started...' -ForegroundColor Cyan

    Start-Process -FilePath "$deployPath\Deploy-Application.exe" -Wait
    Write-Host 'Installation completed' -ForegroundColor DarkGreen

    Write-Host "You have $VerificationTime seconds to verify the installation before it is automatically uninstalled." -ForegroundColor Cyan

    $EndTime = [datetime]::UtcNow.AddSeconds($VerificationTime)

    while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
        Write-Progress -Activity 'Waiting for...' -Status testing -SecondsRemaining $TimeRemaining.TotalSeconds
        Start-Sleep 1
    }

    if (!(Read-Host -Confirm "Are you sure you want to uninstall $Application?")) {
        Write-Host 'Uninstall cancelled.' -ForegroundColor Yellow
        Exit
    }

    Start-Process -FilePath "$deployPath\Deploy-Application.exe" -ArgumentList 'Uninstall' -Wait
    Write-Host 'test completed' -ForegroundColor DarkGreen
} else {
    Write-Error "Deploy-Application.exe not found in $deployPath"
}

Write-Host 'You can close sandbox now!' -ForegroundColor Cyan
Read-Host -Prompt 'Press any key to continue...'

