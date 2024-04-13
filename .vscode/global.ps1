# Vars
[string]$Repo = 'E:\DevOps\PackageBuilds' # Repo for software testing
[string]$wsbResources = "$env:ProgramData\WindowsSandboxResources" # Staging location of WSB resource files
[string]$Desktop = [Environment]::GetFolderPath('DesktopDirectory') # Gets the Desktop directory path
[string]$WDADesktop = "$env:SystemDrive\Users\WDAGUtilityAccount\Desktop" #Sandbox user desktop folder #WSB Resource Folder
[string]$Win32App = "$env:ProgramData\win32app" # Parent folder for staging cache and resources folders to load into WSB
$globalScriptPth = Split-Path $PSScriptRoot -Parent
[string]$Application = Split-Path $globalScriptPth -Leaf
[string]$Cache = "$env:ProgramData\win32app\$Application" # WSB App package cache folder.
[string]$Resources = "$env:ProgramData\win32app\Resources" # Cache location for WSB resource files
[string]$LogonCommand = 'Bootstrap.ps1' # PS file to be ran when WSB loads

Write-Host "Script's Parent Folder: $Application"

# Copy Cache
Remove-Item -Path "$Cache" -Recurse -Force -ErrorAction Ignore
Copy-Item -Path 'Toolkit' -Destination "$Cache" -Recurse -Force -Verbose -ErrorAction Ignore

# uncomment below command to open the $Cache location in explorer.
#explorer "$Cache"
