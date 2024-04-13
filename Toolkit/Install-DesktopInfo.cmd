@echo off
:: Define the path to the PowerShell script
set "PowerShellScript=%~dp0DesktopInfo.ps1"

:: Define the parameters for the PowerShell script
:: If your script has custom parameters add them below as a variable then add them to the powershell command.
set "DeploymentType=Install"
set "DeployMode=Silent"

:: Run the PowerShell script silently

powershell -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "%PowerShellScript%" -DeploymentType %DeploymentType% -DeployMode %DeployMode%
