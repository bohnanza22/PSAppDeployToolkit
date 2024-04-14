# Vars

[string]$Repo         = "E:\DevOps\PackageBuilds" # Repo for software testing
[string]$wsbResources = "$env:ProgramData\WindowsSandboxResources" # Staging location of WSB resource files
[string]$Desktop      = [Environment]::GetFolderPath('DesktopDirectory') # Gets the Desktop directory path
[string]$WDADesktop   = "$env:SystemDrive\Users\WDAGUtilityAccount\Desktop" #Sandbox user desktop folder #WSB Resource Folder
[string]$Win32App     = "$env:ProgramData\win32app" # Parent folder for staging cache and resources folders to load into WSB
[string]$Application  = "$(& git branch --show-current)" # Gets the VSCode git branch name
[string]$Cache        = "$env:ProgramData\win32app\$Application" # WSB App package cache folder.
[string]$Resources    = "$env:ProgramData\win32app\Resources" # Cache location for WSB resource files
[string]$LogonCommand = "Bootstrap.ps1" # PS file to be ran when WSB loads
[string]$psadtMaster  = 'E:\DevOps\PSADT-Master\PSAppDeployToolkit' # Location of your PSADT Mater repo you clone your projects from
[string]$psadtProject = 'E:\DevOps\PSADT-Projects' # Location of your PSADT Projects
