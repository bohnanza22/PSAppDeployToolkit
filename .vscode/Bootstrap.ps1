# Windows Sandbox Logon/Bootstrap Script
# Global Functions
# Master Script found here: https://github.com/Strappazzon/wsb
#
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$Application,
    [int]$VerificationTime = 60  # Optional parameter for verification time
)

Function Disable-Volume {
    <#
	.SYNOPSIS
	Mute sounds volume
	.LINK
	https://stackoverflow.com/a/12397737
	#>

    $obj = New-Object -ComObject WScript.Shell
    $obj.SendKeys([Char]173)
}

<#
.SYNOPSIS
Creates a shortcut for a file or folder.

.DESCRIPTION
The New-Shortcut function creates a shortcut for a file or folder on the local system. You can specify the target path, shortcut path, arguments, description, and icon location.

.PARAMETER TargetPath
The path to the file or folder you want to create a shortcut for.

.PARAMETER ShortcutPath
The path and filename for the shortcut you want to create.

.PARAMETER Arguments
(Optional) Any arguments to pass to the target application.

.PARAMETER Description
(Optional) A description for the shortcut.

.PARAMETER IconLocation
(Optional) The path to the icon you want to use for the shortcut.

.EXAMPLE
New-Shortcut -TargetPath "C:\path\to\file.exe" -ShortcutPath "C:\Users\YourUsername\Desktop\MyFile.lnk"
Creates a shortcut for a file on the desktop.

.EXAMPLE
New-Shortcut -TargetPath "C:\path\to\folder" -ShortcutPath "C:\Users\YourUsername\Desktop\MyFolder.lnk"
Creates a shortcut for a folder on the desktop.

.EXAMPLE
New-Shortcut -TargetPath "C:\path\to\file.exe" -ShortcutPath "C:\Users\YourUsername\Desktop\MyFile.lnk" -Arguments "-param1 value1" -Description "My File Shortcut" -IconLocation "C:\path\to\icon.ico"
Creates a shortcut for a file on the desktop with additional options.

.NOTES
This function requires the Windows Script Host (WScript.Shell) COM object to create the shortcut.
#>
function New-Shortcut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath,
        [string]$Arguments,
        [string]$Description,
        [string]$IconLocation
    )

    try {
        # Create a new shell object
        $WshShell = New-Object -ComObject WScript.Shell

        # Create the shortcut
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = [System.IO.Path]::GetFullPath($TargetPath)
        $Shortcut.Arguments = $Arguments
        $Shortcut.Description = $Description
        $Shortcut.IconLocation = $IconLocation
        $Shortcut.Save()

        Write-Output "Shortcut created: $ShortcutPath"
    } catch {
        Write-Error "Error creating shortcut: $_"
    }
}

Function Update-Wallpaper([String]$Image) {
    <#
	.SYNOPSIS
	Applies a specified wallpaper to the current user Desktop
	.PARAMETER Image
	Path to the image
	.EXAMPLE
	Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
	.LINK
	https://www.joseespitia.com/2017/09/15/set-wallpaper-powershell-function/
	#>

    Add-Type -TypeDefinition @'
	using System;
	using System.Runtime.InteropServices;
	public class Params {
		[DllImport("User32.dll",CharSet=CharSet.Unicode)]
		public static extern int SystemParametersInfo (Int32 uAction, Int32 uParam, String lpvParam, Int32 fuWinIni);
	}
'@

    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02

    $fWinIni = $UpdateIniFile -bor $SendChangeEvent

    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
}

Function Restart-Explorer {
    <#
	.SYNOPSIS
	Restart Windows Explorer
	#>

    Get-Process -Name Explorer | Stop-Process -Force
    # Give Windows Explorer time to start
    Start-Sleep -Seconds 3

    # Verify that Windows Explorer has restarted
    Try {
        $p = Get-Process -Name Explorer -ErrorAction Stop
    } Catch {
        Try {
            Start-Process explorer.exe
        } Catch {
            # This should never be called
            Throw $_
        }
    }
}
function Wait-ProcessCompletion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    do {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "Waiting for $ProcessName to complete..."
            Start-Sleep -Seconds 1
        }
    } until ($process -eq $null)
}

#
# Start
#

# Variables
[string]$Resources = "$env:SystemDrive\Resources"
[string]$WDADesktop = "$env:SystemDrive\Users\WDAGUtilityAccount\Desktop"
[string]$deployPath = "$WDADesktop\$Application"

#
# Personalization
#
if (Test-Path -Path "$Resources\Software Logs.lnk") {
    Write-Host "$Resources\Software Logs.lnk exists." -ForegroundColor Green
    Copy-Item -Path "$Resources\Software Logs.lnk" -Destination "$WDADesktop" -Force -Verbose -ErrorAction Ignore
} else {
    Write-Host "$Resources\Software Logs.lnk  is NOT in this location." -ForegroundColor DarkYellow
}

if (Test-Path -Path "$Resources\CMTrace.exe") {
    Write-Host "$Resources\CMTrace.exe  exists." -ForegroundColor Green
    if (Test-Path -Path "$Resources\Software Logs.lnk") {
        Write-Host "$Resources\CMTrace.lnk  exists." -ForegroundColor Green
        Copy-Item -Path "$Resources\CMTrace.lnk" -Destination "$WDADesktop" -Force -Verbose -ErrorAction Ignore
    } else {
        Write-Host "$Resources\CMTrace.lnk  is NOT in this location." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "$Resources\CMTrace.exe  is NOT in this location." -ForegroundColor DarkYellow
}

Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name 'Wallpaper' -Value "$Resources\Desktop.png" -Verbose

# Change Wallpaper
<# Update-Wallpaper -Image "$Resources\Desktop.png"
Invoke-Command { c:\windows\System32\RUNDLL32.EXE user32.dll, UpdatePerUserSystemParameters 1, True } #>

# Disable News and Interests
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds' -Name 'ShellFeedsTaskbarViewMode' -Type DWord -Value 2 -Force -Verbose
# Hide search in taskbar
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchboxTaskbarMode' -Type DWord -Value 1 -Verbose
# Small taskbar icons
#Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarSmallIcons' -Type DWord -Value 1 -Verbose
# Hide Task View button in taskbar
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Type DWord -Value 0 -Verbose
# Light theme
#Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Type DWord -Value 1 -Verbose
#Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Type DWord -Value 1 -Verbose
# Small desktop icons
#Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop' -Name 'IconSize' -Type DWord -Value 32 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop' -Name 'LogicalViewMode' -Type DWord -Value 3 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop' -Name 'Mode' -Type DWord -Value 1 -Verbose
# Performance settings
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Type String -Value 0 -Verbose
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value 200 -Verbose
Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name 'KeyboardDelay' -Type DWord -Value 0 -Verbose
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Type Binary -Value ([byte[]](144, 18, 3, 128, 16, 0, 0, 0)) -Verbose
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Type String -Value 0 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect' -Type DWord -Value 0 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow' -Type DWord -Value 0 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Type DWord -Value 0 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Type DWord -Value 3 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' 'EnableAeroPeek' -Type DWord -Value 0 -Verbose
# Display Windows version over wallpaper
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'PaintDesktopVersion' -Type DWord -Value 1 -Verbose
# Show file name extensions
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Type DWord -Value 0 -Verbose
# Show hidden and protected system files
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Type DWord -Value 1 -Verbose
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSuperHidden ' -Type DWord -Value 1 -Verbose
# Make navigation pane show all folders
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'NavPaneShowAllFolders' -Type DWord -Value 1 -Verbose
# Open explorer to This PC
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Type DWord -Value 1 -Verbose

# Associate .log files with cmTrace
New-Item -Path 'HKLM:\Software\Classes\.lo_' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\.log' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\.log.File' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\.Log.File\shell' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\Log.File\shell\Open' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\Log.File\shell\Open\Command' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Microsoft\Trace32' -type Directory -Force -ErrorAction SilentlyContinue

# Create the properties to make CMtrace the default log viewer
New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\.lo_' -Name '(default)' -Value 'Log.File' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\.log' -Name '(default)' -Value 'Log.File' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\Log.File\shell\open\command' -Name '(default)' -Value "`"C:\Resources\CMTrace.exe`" `"%1`"" -PropertyType String -Force -ea SilentlyContinue;

<# # Create an ActiveSetup that will remove the initial question in CMtrace if it should be the default reader
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace' -type Directory
New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace' -Name 'Version' -Value 1 -PropertyType String -Force
New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace' -Name 'StubPath' -Value 'reg.exe add HKCU\Software\Microsoft\Trace32 /v "Register File Types" /d 0 /f' -PropertyType ExpandString -Force #>

# Mute sounds
Disable-Volume

Restart-Explorer


# test for the Deploy-Application.exe file
if (Test-Path -Path "$deployPath\Deploy-Application.exe") {
    Write-Host 'Testing has started...' -ForegroundColor Cyan
    # Start deployment with .exe
    Start-Process -FilePath "$deployPath\Deploy-Application.exe" -Wait
    Wait-ProcessCompletion -ProcessName 'Deploy-Application'
    Write-Host 'Install completed' -ForegroundColor Green
    Write-Host "You have $VerificationTime seconds to verify the installation before it is automatically uninstalled." -ForegroundColor Cyan

    # Waiting for manual verification of deployment
    $EndTime = [datetime]::UtcNow.AddSeconds($VerificationTime)

    while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
        Write-Progress -Activity 'Waiting for...' -Status testing -SecondsRemaining $TimeRemaining.TotalSeconds
        Start-Sleep 1
    }

    # Present uninstall choice
    if (!(Read-Host -Confirm "Are you sure you want to uninstall $Application?")) {
        Write-Host 'Uninstall cancelled.' -ForegroundColor Yellow
        Exit
    }

    # Start uninstall
    Start-Process -FilePath "$deployPath\Deploy-Application.exe" -ArgumentList 'Uninstall' -Wait
    Wait-ProcessCompletion -ProcessName 'Deploy-Application'
    Write-Host 'Uninstall completed' -ForegroundColor Green
    Start-Sleep 3
    Write-Host 'Test completed' -ForegroundColor DarkGreen

    # Test for powershell script file
} elseif (Test-Path -Path "$deployPath\$Application.ps1") {
    # Test for a cmd script file
    if (Test-Path -Path "$deployPath\Install-$Application.cmd") {
        # Start deployment with cmd file
        Write-Host 'Testing has started...' -ForegroundColor Cyan
        Start-Process -FilePath "$deployPath\Install-$Application.cmd" -RedirectStandardOutput "$env:WinDir\Logs\Software\Install-$Application-cmd.log" -Wait -WindowStyle Hidden -ErrorAction Continue
        #Wait-ProcessCompletion -ProcessName "$Application"
        Write-Host 'Installation completed' -ForegroundColor Green

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

        # Start uninstall
        Start-Process -FilePath "$deployPath\Uninstall-$Application.cmd" -RedirectStandardOutput "$env:WinDir\Logs\Software\Uninstall-$Application-cmd.log" -Wait -WindowStyle Hidden -ErrorAction Continue
        #Wait-ProcessCompletion -ProcessName "$Application"
        Write-Host 'Uninstall completed' -ForegroundColor Green
        Start-Sleep 3
        Write-Host 'Test completed' -ForegroundColor DarkGreen
    } else {
        # Start testing with the powershell file
        Write-Host 'Testing has started...' -ForegroundColor Cyan
        Start-Process Powershell.exe -ArgumentList "-ExecutionPolicy Bypass -ProcessName '$Application' -File '$deployPath\$Application.ps1' -DeploymentType Install" -Wait
        Wait-ProcessCompletion -ProcessName 'Powershell'
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

        # Start Uninstall
        Start-Process Powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File '$deployPath\$Application.ps1' -DeploymentType Uninstall" -Wait
        Wait-ProcessCompletion -ProcessName 'Powershell'
        Write-Host 'Uninstall completed' -ForegroundColor Green
        Start-Sleep 3
        Write-Host 'Test completed' -ForegroundColor DarkGreen
    }
} else {
    Write-Error "No resources available in $deployPath to initiate test install."
}

Write-Host 'You can close sandbox now!' -ForegroundColor Cyan
Read-Host -Prompt 'Press any key to continue...'

#
# End
#


