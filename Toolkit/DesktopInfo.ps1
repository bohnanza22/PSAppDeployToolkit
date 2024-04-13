<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2024 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Workstation.ini', 'Advanced')]
    [String]$ini = 'Workstation'
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    } Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = 'Glen Delahoy'
    [String]$appName = 'Desktop Info'
    [String]$appVersion = '3.13.0'
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '02'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '4/11/2024'
    [String]$appScriptAuthor = 'Willis Spires'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)

    #[string]$installName = ''
    [string]$installTitle = $appName # can be customized by removing the $appName and replacing it with something like: 'Custom ARP Name' | used by Custom ARP, PSADT GUI prompts, PSADT balloonTip/toasts
    [string]$installName = ($MyInvocation.MyCommand.Name).Replace('.ps1', '')  # e.g. 'used by Custom ARP, localDiskUninstall, etc.
    [string]$AppMSIName = '' # actual name of the MSI in the \Files folder
    [string]$AppMSICode = '' # MSI Product Code of MSI above (used for removal)
    [string]$AppEXEName	= '' # actual file name of the .EXE installer in the \Files folder
    ## Use the above custom variables with the following install command examples:
    <#
		#* EXE Install Command Example
		[String]$AppEXEArgs = "/S"
		Execute-Process -Path "$dirFiles\$AppEXEName" -Parameters $AppEXEArgs -WaitForMsiExec:$true -WindowStyle 'Hidden'

		#* MSI Install Command Example
		[String]$AppMSIArgs = "PROPERTY=`"https://ExampleProperty.com`" /qn"
		Execute-MSI -Action Install -Path $AppMSIName -AddParameters $AppMSIArgs -ContinueOnError $False -LogName "${AppMSIName}_MSI_Install.log"

		#* MSI Unnstall Command
		[String]$AppMSIArgs = "/qn"
		Execute-MSI -Action Unnstall -Path $AppMSICode -AddParameters $AppMSIArgs -ContinueOnError $False -LogName "${AppMSIName}_MSI_Uninstall.log"
		#>


    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.10.0'
    [String]$deployAppScriptDate = '03/27/2024'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## TODO Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        Show-InstallationWelcome -CloseApps 'DesktopInfo,DesktopInfo32,DesktopInfo64' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

        ## TODO Show Progress Message (with the default message)
        Show-InstallationProgress

        ## TODO  <Perform Pre-Installation tasks here>
        Remove-MSIApplications -Name 'Desktop Info'

        $pthDesktopInfo = "$env:PUBLIC\DesktopInfo"

        if ($pthDesktopInfo) {
            Remove-Folder -Path $pthDesktopInfo -Verbose
        }

        # Define the directory where you want to search for the file
        #$directory = "C:\Path\To\Directory"
        $startupPth = "$envProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

        # Get all files in the directory that match the pattern '*DesktopInfo*'
        $file = Get-ChildItem -Path $startupPth -Filter "*Desktop*Info*" | Select-Object -First 1

        # Check if a file was found
        if ($file) {
            # Delete the file
            Remove-File -Path $file.FullName

            Write-log -Message "File $($file.Name) deleted." -Severity 1 -Source $installPhase

        }
        else {
            Write-log -Message "No file matching '*Desktop*Info*' found in $directory." -Severity 1 -Source $installPhase

        }

        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        Set-LocalDiskUninstall 	#Needed for Custom ARP entry to work

        ## Handle Zero-Config MSI Installations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) {
                $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ }
            }
        }
        ## TODO <Perform Installation tasks here>

        $source = "$dirFiles\*.*"
        $destination = "$envProgramfiles\DesktopInfo"
        Copy-File -Path $source -Destination $destination -Recurse -Verbose

        New-Shortcut -Path "$envProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\DesktopInfo.lnk" `
            -TargetPath "$envProgramfiles\DesktopInfo\DesktopInfo64.exe" `
            -Arguments "/ini=`"$ini.ini`"" `
            -IconLocation "$envProgramfiles\DesktopInfo\DesktopInfo64.exe" `
            -Description 'DesktopInfo'
        #-WorkingDirectory "$envHomeDrive\$envHomePath"

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## TODO <Perform Post-Installation tasks here>

        #*This should be placed near the **end** of the INSTALLATION section
        #*Set-CustomARP uses \SupportFiles\$InstallName.ico if possible, otherwise uses PSADT icon (AppDeployToolkitLogo.ico) for Custom ARP entry
        Set-CustomARP

        Write-log -Message "Logged on Users: $($usersLoggedOn -join ', ')" -Severity 1 -Source $installPhase

        if ($usersLoggedOn) {
            Write-log -Message "The logged-on user is $($usersLoggedOn.UserName)" -Severity 1 -Source $installPhase
            Write-log -Message "Attempting to start Desktop Info." -Severity 1 -Source $installPhase
            Execute-Process -Path "$envProgramfiles\DesktopInfo\DesktopInfo64.exe" -Parameters "$ini.ini" -NoWait
        }
        else {
            Write-log -Message "No user is logged in. Not starting DesktopInfo" -Severity 1 -Source $installPhase
        }

        ## TODO Display a message at the end of the install
        If (-not $useDefaultMsi) {
            Show-InstallationPrompt -Message "$installTitle has been installed." -ButtonRightText 'OK' -Icon Information -NoWait
        }
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## TODO Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'DesktopInfo,DesktopInfo32,DesktopInfo64' -CloseAppsCountdown 60

        ## TODO Show Progress Message (with the default message)
        Show-InstallationProgress

        ## TODO <Perform Pre-Uninstallation tasks here>


        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## Handle Zero-Config MSI Uninstallations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }

        ## TODO <Perform Uninstallation tasks here>

        Start-Sleep -Seconds 5

        $startupPth = "$envProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

        # Remove Desktop Info startup shortcut
        # Get all files in the directory that match the pattern '*DesktopInfo*'
        $file = Get-ChildItem -Path $startupPth -Filter "*Desktop*Info*" | Select-Object -First 1

        # Check if a file was found
        if ($file) {
            # Delete the file
            Remove-File -Path $file.FullName -Verbose
            Write-log -Message "File $($file.Name) deleted." -Severity 1 -Source $installPhase

        }
        else {
            Write-log -Message "No file matching '*Desktop*Info*' found in $directory." -Severity 1 -Source $installPhase

        }

        # Remove DTI installation files.
        $dtiProgramFolder = "$envProgramfiles\DesktopInfo"
        Remove-Folder -Path "$dtiProgramFolder" -Verbose

        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## TODO <Perform Post-Uninstallation tasks here>

        #* This should be placed near the **end** of the UNINSTALLATION section
        Set-CustomARP -PkgName $InstallName -Remove
        Set-LocalDiskUninstall -PkgName $InstallName -Remove

    }
    ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ## TODO Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## TODO Show Progress Message (with the default message)
        Show-InstallationProgress

        ## TODO <Perform Pre-Repair tasks here>

        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]$installPhase = 'Repair'

        ## Handle Zero-Config MSI Repairs
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        ## TODO <Perform Repair tasks here>

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## TODO <Perform Post-Repair tasks here>


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
