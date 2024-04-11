#LogonCommand.ps1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$Application,
    [int]$VerificationTime = 60  # Optional parameter for verification time
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
}

elseif (Test-Path -Path "$deployPath\$Application.ps1") {

    If (Test-Path -Path "$deployPath\Install-$Application.cmd") {

        Invoke-Item -Path "$deployPath\Install-$Application.cmd" -Verbose
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

        Invoke-Item -Path "$deployPath\Uninstall-$Application.cmd" -Verbose
        Write-Host 'test completed' -ForegroundColor DarkGreen
    }
    else {

        Start-Process Powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File '$deployPath\$Application.ps1' -DeploymentType Install" -Wait
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

        Start-Process Powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File '$deployPath\$Application.ps1' -DeploymentType Uninstall" -Wait
        Write-Host 'test completed' -ForegroundColor DarkGreen
    }
}
else {

    Write-Error "No resources available in $deployPath to iniate test install."
}

Write-Host 'You can close sandbox now!' -ForegroundColor Cyan
Read-Host -Prompt 'Press any key to continue...'

