<#
.SYNOPSIS

PSAppDeployToolkit - Provides the ability to extend and customise the toolkit by adding your own functions that can be re-used.

.DESCRIPTION

This script is a template that allows you to extend the toolkit with your own custom functions.

This script is dot-sourced by the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2024 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE

powershell.exe -File .\AppDeployToolkitHelp.ps1

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'3.10.0'
[string]$appDeployExtScriptDate = '03/27/2024'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>
# TODO region Function Set-CustomARP
Function Set-CustomARP {
    <#
    .SYNOPSIS
        Creates/removes custom ARP entries
        This is used to hide multiple ARP entries under ONE custom ARP entry
        Makes uninstalling complex packages uninstall using a PSADT script
        Makes it possible to get a log file when uninstalling from ARP
        Makes ARP/Program and Features/ cleaner, easier to understand
    .DESCRIPTION
        Creates/removes custom ARP entries to make it possible to get a log file when uninstalling from ARP
        You can force it to be 32Bit, 64Bit, but defaults to Auto
        'Auto' makes it search for its "children" in both by looking for "ArpKeyName" values in other ARP entries's ParentKeyName value (using Set-ARPChildOfParent)
            If no children are found, the Custom ARP entry will be 64bit.
            If both are found, the Custom ARP entry will be 64bit.
        Set-CustomARP must be called *AFTER*:
            -Set-LocalDiskUninstall function (Usually before installing packages)
            -ALL packages (MSI/EXE/Etc.) are installed
            -Set-ARPChildOfParent function is called to hide ARP entry of each (MSI/EXE/Etc.)
        NOTE: Set-ARPChildOfParent function will create ParentKeyName values that this function looks for.
        NOTE: ARP = Add/Remove Programs = Programs and Features = Apps & Features
    .PARAMETER ArpKeyName
        Name of Registry Key of the NEW ARP entry, Defaults to $installName (PSADT var)
        Has Alias of PkgName
    .PARAMETER ArpDisplayName
        Name that will be shown in ARP/Programs&Features entry, Defaults to $installTitle (PSADT var)
    .PARAMETER ArpContact
        Contact that will be shown in ARP/Prog&Features entry, Defaults to $appScriptAuthor (PSADT var)
    .PARAMETER ArpPublisher
        Publisher that will be shown in ARP/Prog&Features entry, Defaults to $ArpContact (mentioned above)
    .PARAMETER ArpDisplayIcon
        Full Path to the Icon that will be shown in ARP/Prog&Features entry,
        Defaults to \SupportFiles\$InstallName.ico in Local uninstall Cache
        If no match occurs, defaults to \AppDeployToolkit\AppDeployToolkitLogo.ico in Local uninstall Cache
        ArpDisplayIcon should be able to be pointed to an .ico or an .exe.
    .PARAMETER ArpDisplayVersion
        Version number that will be shown in ARP/Prog&Features entry, Defaults to $appVersion (PSADT var)
    .PARAMETER ArpInstallDate
        Date of Installation that will be shown in ARP/Prog&Features entry, Defaults to an automatically generated date [Rarely used]
    .PARAMETER ArpUninstallString
        UnInstallation command that will be triggered by this custom ARP/Prog&Features entry, Defaults to uninstalling this $installName.ps1 from Local uninstall Cache
        CAVEATS:
        -UninstallString does not support file association so you must specify the Exe
        -Windows7-Progs&Feature (aka ARP) is 32bit, we specified a full path to PowerShell.exe
        -Windows10-Progs&Feature (aka ARP) is 64bit but Win10 also has APPs&Feature where specifying a full path to the EXE will make it fail to launch.
    .PARAMETER ArpEstimatedSize
        Estimated Size of installed application will be shown in ARP/Prog&Features entry.
        Uses size of files in \Files folder. If none, defaults to a bogus value.
        This is required or else ARP/Prog&Features takes longer to display while Windows
        goes on a scavenger hunt for the size and wastes your time as Prog&Features loads!
    .PARAMETER BitNess
        Sets the bitness of the ARP entry - Optional [Rarely used]
        Can be forced to 32Bit,64Bit or Auto. Defaults to 'Auto'.
    .PARAMETER Remove
        Removes the custom ARP entry
    .PARAMETER ExistTest
        Returns $true or $false if $ArpKeyName exist in ARP region of the registry. 32 or 64 bit [Rarely used]
    .PARAMETER ContinueOnError
        Continue if an error is encountered. Default is: $false.
    .EXAMPLE
        Set-CustomARP
        Creates ARP Entry using $InstallName.ico or AppDeployToolkitLogo.ico in local Uninstall folder ($configLocalUninstallCache)
    .EXAMPLE
        Set-CustomARP -ArpDisplayIcon "C:\Program Files\1E\Agent\WakeUp\WakeUpAgt.exe"
        Creates ARP Entry and uses the first icon in WakeUpAgt.exe
    .EXAMPLE
        Set-CustomARP -ContinueOnError $false
    .EXAMPLE
        Set-CustomARP -PkgName $installName -Remove
        Remove the custom ARP entry
    .EXAMPLE
        Set-CustomARP -ArpKeyName $installName -Remove
        Remove the custom ARP entry
    .EXAMPLE
        Set-CustomARP -ExistTest
        Tests if ARP entry for $installName exists.
    .NOTES
        Author: Denis St-Pierre (Ottawa, Canada)
        -Tested on Windows 10 and Windows 7
        Base on concepts by Todd MacNaught (Ottawa, Canada)
        Depends on Set-LocalDiskUninstall and Set-ARPChildOfParent functions
        Uses $configLocalUninstallCache to point to an existing folder e.g. c:\AdmUtils\uninstall
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = "Registry key name for ARP Entry - Optional")]
        [ValidateNotNullorEmpty()]
        [Alias('PkgName')]
        [string]$ArpKeyName = $installName,
        [Parameter(Mandatory = $false, HelpMessage = "DisplayName for ARP Entry - Optional")]
        [ValidateNotNullorEmpty()]
        [String]$ArpDisplayName = $installTitle,
        [Parameter(Mandatory = $false, HelpMessage = "Contact for ARP Entry - Optional")]
        [ValidateNotNullOrEmpty()]
        [String]$ArpContact = $appScriptAuthor,
        [Parameter(Mandatory = $false, HelpMessage = "Publisher for ARP Entry - Optional")]
        [ValidateNotNullorEmpty()]
        [String]$ArpPublisher = $appVendor,
        [Parameter(Mandatory = $false, HelpMessage = "Icon for ARP Entry (Path on Target or Deploy-Application_v1r1.ico) - Optional")]
        [ValidateNotNullorEmpty()]
        [String]$ArpDisplayIcon = $(If (Test-Path "$configLocalUninstallCache\$InstallName\SupportFiles\$InstallName.ico") { "$configLocalUninstallCache\$InstallName\SupportFiles\$InstallName.ico" } else { "$configLocalUninstallCache\${ArpKeyName}\AppDeployToolkit\AppDeployToolkitLogo.ico" }),
        [Parameter(Mandatory = $false, HelpMessage = "Version number for ARP Entry - Optional")]
        [ValidateNotNullorEmpty()]
        [String]$ArpDisplayVersion = $appVersion,
        [Parameter(Mandatory = $false, HelpMessage = "Date of Installation for ARP Entry - Optional")]
        [ValidateNotNullorEmpty()]
        [string]$ArpInstallDate = ((Get-Date -Format 'yyyyMMdd').ToString()), # Ex: 20150720
        [Parameter(Mandatory = $false, HelpMessage = "UnInstallation command for ARP Entry - Optional")]
        [ValidateNotNullorEmpty()]
        [string]$ArpUninstallString = "PowerShell -executionpolicy bypass -file `"$configLocalUninstallCache\$ArpKeyName\${InstallName}.ps1`" Uninstall NonInteractive",
        [Parameter(Mandatory = $false, HelpMessage = "EstimatedSize of installed application for ARP Entry - Optional")]
        [ValidateNotNullOrEmpty()]
        [String]$ArpEstimatedSize,
        [Parameter(Mandatory = $false, HelpMessage = "Sets the bitness of the ARP entry - Optional")]
        [ValidateSet('32Bit', '64Bit', 'Auto')]
        [String]$BitNess = 'Auto',
        [Parameter(Mandatory = $false, HelpMessage = "Removes custom ARP entry")]
        [ValidateNotNullorEmpty()]
        [Switch]$Remove = $false,
        [Parameter(Mandatory = $false, HelpMessage = 'Tests for custom ARP entries, returns $true or $false.')]
        [ValidateNotNullorEmpty()]
        [Switch]$ExistTest = $false,
        [Parameter(Mandatory = $false)]
        [boolean]$ContinueOnError = $false
    )
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        Try {
            Try {
                #Can't use PSADT's [Array]$regKeyApplications because we need to know if it's 32 or 64 bit.
                [string]$HKLMUninstallKey64bit	= 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                [string]$HKLMUninstallKey32bit	= 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

                If ($ExistTest) {
                    If ($ArpKeyName -match ":\\") {
                        Write-Log "`$ArpKeyName [$ArpKeyName] contains illegal characters ':\' " -Source ${CmdletName} -Severity 3
                        Throw "`$ArpKeyName contains illegal characters ':\' "
                    }
                    $ArpFound = $false
                    ForEach ($regKey in $regKeyApplications) {
                        #$regKeyApplications is from PSADT. Table holds 32 and 64 bit ARP locations
                        [string]$_TARGETPKGUNINSTALLKEY = "$regKey\$ArpKeyName"
                        Write-Log "Looking for [$_TARGETPKGUNINSTALLKEY] to TEST for ARP entry ..." -Source ${CmdletName}
                        If (Test-Path $_TARGETPKGUNINSTALLKEY) {
                            Write-Log "Found [$ArpKeyName] ARP entry" -Source ${CmdletName}
                            $ArpFound = $true
                        }
                    }
                    Write-Output $ArpFound
                } ElseIf ($Remove) {
                    #Remove ARP entry
                    [Int32]$numOfRemovedArpEntries = 0
                    ForEach ($regKey in $regKeyApplications) {
                        #$regKeyApplications is from PSADT. Table holds 32 and 64 bit ARP locations
                        [string]$_TARGETPKGUNINSTALLKEY = "$regKey\$ArpKeyName"
                        Write-Log "Looking for [$_TARGETPKGUNINSTALLKEY] to remove ARP entry ..." -Source ${CmdletName}
                        If (Test-Path $_TARGETPKGUNINSTALLKEY) {
                            Write-Log "Removing [$ArpKeyName] ARP entry" -Source ${CmdletName}
                            Remove-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -ContinueOnError $ContinueOnError
                            $numOfRemovedArpEntries++ #CAVEAT: Don't Cast and increment at the same time or it will output the value
                        }
                    }
                    If ( $numOfRemovedArpEntries -lt 1 ) {
                        Write-Log "ARP Entry [$ArpKeyName] does not exist. Nothing to Delete." -Severity 2 -Source ${CmdletName}
                    }
                } Else {
                    #Create ARP entry
                    Write-log "Using [$ArpDisplayIcon] for ARP icon" -Source ${CmdletName}

                    #Determine BitNess of Arp entry
                    If ($BitNess -eq 'Auto') {
                        Write-Log "Looking for ARP Children with ParentKeyName set to [$ArpKeyName]..." -Source ${CmdletName}
                        Remove-Variable AllArpKeys, ArpKey, Values -ErrorAction SilentlyContinue
                        [System.Array]$AllArpKeys = Get-ChildItem -Path $HKLMUninstallKey32bit -ErrorAction Stop
                        ForEach ($ArpKey in $AllArpKeys) {
                            [PSObject]$Values = $ArpKey | ForEach-Object { Get-ItemProperty $_.PsPath -ErrorAction Stop }
                            If ( $Values.ParentKeyName -eq $ArpKeyName) {
                                [String]$BitNess = '32Bit'
                                Write-Log "Found 32bit Child [$($Values.DisplayName)]	Keyname:[$($ArpKey.PSChildName)]" -Source ${CmdletName}
                            }
                        }
                        Remove-Variable AllArpKeys, ArpKey, Values -ErrorAction SilentlyContinue
                        [System.Array]$AllArpKeys = Get-ChildItem -Path $HKLMUninstallKey64bit -ErrorAction Stop
                        ForEach ($ArpKey in $AllArpKeys) {
                            #[PSObject]$Values = $ArpKey | Foreach-Object { Get-ItemProperty $_.PsPath -ErrorAction Stop } # Origonal code See: https://discourse.psappdeploytoolkit.com/t/create-custom-programs-and-features-entries-arp-entries/4017/10
                            #If ( $Values.ParentKeyName -eq $ArpKeyName) { # Origonal code See: https://discourse.psappdeploytoolkit.com/t/create-custom-programs-and-features-entries-arp-entries/4017/10
                            If ( $($ArpKey.PSChildName) -eq $ArpKeyName) {
                                [String]$BitNess = '64Bit'
                                #Write-Log "Found 64bit Child [$($Values.DisplayName)]	Keyname:[$($ArpKey.PSChildName)]" -Source ${CmdletName} # Origonal code See: https://discourse.psappdeploytoolkit.com/t/create-custom-programs-and-features-entries-arp-entries/4017/10
                                Write-Log "Found 64bit Child [$($ArpKey.GetValue('DisplayName'))]	Keyname:[$($ArpKey.PSChildName)]" -Source ${CmdletName}
                            }
                        }
                        If ($BitNess -eq $null) {
                            [String]$BitNess = '64Bit'
                            Write-Log "No Children ARP entries found. Defaulting to [$BitNess]"  -Source ${CmdletName} -Severity 2
                        }
                    }
                    If ($BitNess -eq '32Bit') {
                        [string]$_TARGETPKGUNINSTALLKEY = "$HKLMUninstallKey32bit\${ArpKeyName}"
                    } Else {
                        [string]$_TARGETPKGUNINSTALLKEY = "$HKLMUninstallKey64bit\${ArpKeyName}"
                    }

                    Write-Log "Creating [$BitNess] ARP entry for [${ArpKeyName}]" -Source ${CmdletName}
                    Write-Log "Variable `$_TARGETPKGUNINSTALLKEY resolved to [$_TARGETPKGUNINSTALLKEY]."  -Source ${CmdletName}
                    Write-Log "Variable `$ArpUninstallString resolved to [$ArpUninstallString]."  -Source ${CmdletName}
                    Write-Log "Variable `$ArpInstallDate resolved to [$ArpInstallDate]."  -Source ${CmdletName}
                    Write-Log "Variable `$ArpDisplayIcon resolved to [$ArpDisplayIcon]."  -Source ${CmdletName}

                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "Contact" -Value $ArpContact -Type String -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "DisplayIcon" -Value $ArpDisplayIcon  -Type String -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "DisplayName" -Value $ArpDisplayName -Type String -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "DisplayVersion" -Value $ArpDisplayVersion  -Type String -ContinueOnError $ContinueOnError

                    If ($ArpEstimatedSize) {
                        Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "EstimatedSize" -Value $ArpEstimatedSize -Type DWord -ContinueOnError $ContinueOnError
                    } else {
                        #NOTE: if EstimatedSize is not set, ARP/Programs and Features goes on a scavenger hunt for the size and wastes time!
                        Try {
                            #  Determine the size of the \Files\ folder
                            $colItems = (Get-ChildItem $dirFiles -Recurse | Measure-Object -Property length -Sum)
                            [int32]$ArpEstimatedSize = ($colItems.sum / 1KB)
                            If ($ArpEstimatedSize -lt 1) {
                                #  Determine the size of the \SupportFiles\ folder
                                $colItems = (Get-ChildItem $dirSupportFiles -Recurse | Measure-Object -Property length -Sum)
                                [int32]$ArpEstimatedSize = ($colItems.sum / 1KB)
                            }
                        } Catch {
                            Write-Log -Message "Failed to calculate disk space requirement from source files (will use bogus value). `r`n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
                            [int32]$ArpEstimatedSize = 6835
                        }
                        Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "EstimatedSize" -Value $ArpEstimatedSize -Type DWord -ContinueOnError $ContinueOnError
                    }

                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "InstallDate" -Value $ArpInstallDate -Type String -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "NoRemove" -Value 0 -Type DWord -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "NoRepair" -Value 1 -Type DWord -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "NoModify" -Value 1 -Type DWord -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "Publisher" -Value $ArpPublisher -Type String -ContinueOnError $ContinueOnError
                    Set-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "UninstallString" -Value $ArpUninstallString -Type ExpandString -ContinueOnError $ContinueOnError
                    If (Test-RegistryValue -Key $_TARGETPKGUNINSTALLKEY -Value 'WindowsInstaller') {
                        #Because Remove-RegistryKey whines in red if not exist
                        Remove-RegistryKey -Key $_TARGETPKGUNINSTALLKEY -Name "WindowsInstaller" -ContinueOnError $true
                    }
                }
            } Catch {
                $Verb = 'create'
                If ($Remove) { $Verb = 'remove' }
                If ($ExistTest) { $Verb = 'Test' }
                Write-Log -Message "Failed to $Verb Custom ARP enter[$ArpKeyName]. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
                If (-not $ContinueOnError) {
                    Throw "Failed to $Verb Custom ARP enter[$ArpKeyName]: $($_.Exception.Message)"
                }
            }
        } Catch {
            [string]$ErrorMessage = "$($_.Exception.Message) $($_.ScriptStackTrace) $($_.Exception.InnerException)"
            Write-Log $ErrorMessage -Severity 3 -Source ${CmdletName}
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion Function Set-CustomARP

# TODO region Function Set-ARPChildOfParent
Function Set-ARPChildOfParent {
    <#
    .SYNOPSIS
        Creates/removes ParentKeyName and ParentDisplayName values in ARP region of registry for a given $ArpKeyName
        These values are also used as flags so that Set-CustomARP will show the as Children of the Custom ARP entry
    .DESCRIPTION
        Creates/removes ParentKeyName and ParentDisplayName values in ARP region of registry for a given $ArpKeyName.
        This function must be run *AFTER* *EACH* Execute-MSI or Execute-Process in the case of setup.exe
        Sets WindowsInstaller=0 even if the ARP entry is from an MSI (Or else the ARP entry does not become a child entry)
        Will also set SystemComponent=0 so that this child entry is not hidden in ARP's "View Installed Updates'

        The Set-CustomARP function must be run *AFTER* this function.
        Set-CustomARP will scan 32bit and 64bit ARP regions of registry for these Parent* values
        and will create its ARP entry to match the bitness of its children.
        NOTE: ARP = Add/Remove Programs = Programs and Features = Apps & Features
        We call it ARP because this idea started with Windows XP
    .PARAMETER ArpKeyName
        Name of Registry Key of the ARP entry to make a Child of $installName (by default)
        This key must exist PRIOR to calling this function (this is why you install the app first)
    .PARAMETER Remove
        Removes the ParentKeyName and ParentDisplayName values that makes the ARP entry a Child of $installName [by default]
    .PARAMETER ParentKeyName
        Keyname of the ARP entry that will be created with Set-CustomARP. Defaults to $installName [Rarely used and highly optional]
    .PARAMETER ParentDisplayName
        Text that will show in ARP that will be created with Set-CustomARP. Defaults to $installTitle [Rarely used and highly optional]
    .PARAMETER IgnoreMissingUninstallString
        By Default, if there is no UninstallString we do not set ParentKeyName because it caused weird issues
        If you still want to set ParentKeyName for the ARP entry in spite of this, set this parameter to $true
        Rarely used
    .PARAMETER OldParentKeyName
        Replaces the contents of ParentKeyName and ParentDisplayName values in existing ARP entries [Rarely used]
        This used when you are releasing a new version of an already deployed package that you do not want to uninstall/reinstall for minor changes.
        This became a need to prevent reinstalling a 3GB package over the VPN for Thousands of people during COVID.
    .PARAMETER ContinueOnError
        Continue if unable to set or remove values or keys. Default is: $false.
        Should default to $true if a removal to prevent failed uninstalls (TODO: try to set in parameters in FUTURE if possible)
    .EXAMPLE
        Set-ARPChildOfParent -ArpKeyName $MSIGUID
    .EXAMPLE
        Adds ParentKeyName and ParentDisplayName for -ArpKeyName $installName
        CAVEAT:You must do this AFTER you install the package that created this ARP Entry.
        Set-ARPChildOfParent -ArpKeyName $installName
    .EXAMPLE
        Removes ParentKeyName and ParentDisplayName for -ArpKeyName $installName
        CAVEAT:You must do this BEFORE you uninstall the package that created this ARP Entry. Otherwise, uninstall may fail or leave junk in the registry.
        Set-ARPChildOfParent -ArpKeyName $installName -Remove
    .EXAMPLE
        Replaces the contents of ParentKeyName and ParentDisplayName values in existing ARP entries where ParentKeyName is currently set to 'MicrosoftOfficeProPlus_V365R1'
        Set-ARPChildOfParent -OldParentKeyName 'MicrosoftOfficeProPlus_V365R1'
    .NOTES
        Author: Denis St-Pierre (Ottawa, Canada)
        -Tested on Windows 10 and Windows 7
        ARP = Add/Remove Programs (Now known as Programs and Features in Windows7 and Apps & Features in Windows10)
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Set', HelpMessage = "name of ARP Registry key to become a Child of another ARP entry")]
        [Parameter(Mandatory = $true, ParameterSetName = 'Remove', HelpMessage = "name of ARP Registry key to become a Child of another ARP entry")]
        [Parameter(Mandatory = $false, ParameterSetName = 'RenameParentKeyName')]
        [ValidateNotNullorEmpty()]
        [string]$ArpKeyName,
        [Parameter(Mandatory = $true, ParameterSetName = 'Remove', HelpMessage = "Removes ParentKeyName and ParentDisplayName values - Optional")]
        [ValidateNotNullorEmpty()]
        [Switch]$Remove = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Removes the Parent* values that makes the ARP entry a Child of `$installName [by default]")]
        [ValidateNotNullOrEmpty()]
        [String]$ParentKeyName = $installName,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$ParentDisplayName = $installTitle,
        [Parameter(Mandatory = $false)]
        [boolean]$IgnoreMissingUninstallString = $False,
        [Parameter(Mandatory = $false, ParameterSetName = 'Set')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Remove')]
        [Parameter(Mandatory = $true, ParameterSetName = 'RenameParentKeyName')]
        [String]$OldParentKeyName,
        [Parameter(Mandatory = $false)]
        [boolean]$ContinueOnError = $false
    )
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header

        [string]$HKLMUninstallKey64bit	= 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        [string]$HKLMUninstallKey32bit	= 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    }
    Process {
        Try {
            [Bool]$FoundArpKey = $false
            ForEach ($Key in @($HKLMUninstallKey64bit, $HKLMUninstallKey32bit) ) {
                #Check in both 32bit and 64bit ARPs
                If (Test-Path -Path "$Key\$ArpKeyName" -PathType Container) {
                    If ($Remove) {
                        Write-log "Removing Parent values in [$ArpKeyName]..." -Source ${CmdletName}
                        Remove-RegistryKey -Key "$Key\$ArpKeyName" -Name 'ParentKeyName' -ContinueOnError $true
                        Remove-RegistryKey -Key "$Key\$ArpKeyName" -Name 'ParentDisplayName' -ContinueOnError $true
                        Remove-RegistryKey -Key "$Key\$ArpKeyName" -Name 'SystemComponent' -ContinueOnError $true
                        #TBD: do we need WindowsInstaller =1 if entry is for an MSI? No but we must remove the value or else the Reg key will stay
                        Remove-RegistryKey -Key "$Key\$ArpKeyName" -Name 'WindowsInstaller' -ContinueOnError $true
                        [Bool]$FoundArpKey = $true
                    } ElseIf ($OldParentKeyName) {
                        Write-log "Replacing ALL Parent values currently set to [$OldParentKeyName]..." -Source ${CmdletName}
                        Write-log "IOW: [$ParentKeyName] is stealing all of [$OldParentKeyName]'s Children in ARP" -Source ${CmdletName}
                        #$OldParentDisplayName is not needed because we are replacing it
                        [Array]$AppKeyArr = Get-ChildItem -Path $Key	#Get all ArpKeyNames. Note: we do this twice. once for 64bit, another for 32bit ARP entries
                        Write-Log "Looking in [$Key]," -Source ${CmdletName}
                        Write-Log "for ARP entries with ParentKeyName = [$OldParentKeyName]" -Source ${CmdletName}
                        ForEach ($AppKey in $AppKeyArr) {
                            If ( $($AppKey.GetValue('ParentKeyName')) -eq $OldParentKeyName) {
                                write-log "Found old parent [$OldParentKeyName] for [$($AppKey.GetValue('DisplayName'))] "  -Source ${CmdletName} -Severity 5
                                Write-Log "[$($AppKey.PSChildName)] setting ParentKeyName to [$ParentKeyName]"  -Source ${CmdletName}
                                Set-RegistryKey -Key $AppKey -Name ParentKeyName -Value $ParentKeyName -Type String
                                Write-Log "[$($AppKey.PSChildName)] setting ParentDisplayName to [$ParentDisplayName]" -Source ${CmdletName}
                                Set-RegistryKey -Key $AppKey -Name ParentDisplayName -Value $ParentDisplayName -Type String
                                [Bool]$FoundArpKey = $true
                            }
                        }
                        write-log "Replacing is done" -Source ${CmdletName} -Severity 5
                    } Else {
                        # check if UninstallString registry value exists. Do not make "ChildOfParent" if none exist as it causes problems (Matt found this issue)
                        If (Test-RegistryValue -Key "$Key\$ArpKeyName" -Value UninstallString) {
                            Write-log "Adding Parent values in [$ArpKeyName]..." -Source ${CmdletName}
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'ParentKeyName' -Value $ParentKeyName -ContinueOnError $false
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'ParentDisplayName' -Value $ParentDisplayName -ContinueOnError $false
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'SystemComponent' -Value 0 -Type DWord -ContinueOnError $true
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'WindowsInstaller' -Value 0 -Type DWord -ContinueOnError $true
                        } ElseIf ($IgnoreMissingUninstallString) {
                            Write-Log "[UninstallString] value in [$ArpKeyName] does not exist but -IgnoreMissingUninstallString is set to TRUE"
                            Write-log "Adding Parent values in [$ArpKeyName]..." -Source ${CmdletName}
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'ParentKeyName' -Value $ParentKeyName -ContinueOnError $false
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'ParentDisplayName' -Value $ParentDisplayName -ContinueOnError $false
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'SystemComponent' -Value 0 -Type DWord -ContinueOnError $true
                            Set-RegistryKey -Key "$Key\$ArpKeyName" -Name 'WindowsInstaller' -Value 0 -Type DWord -ContinueOnError $true
                        } Else {
                            Write-Log "[UninstallString] value  in [$ArpKeyName] does not exist. `r`nNot creating ChildOfParent ARP entries to avoid known issues" -Source ${CmdletName} -Severity 2
                        }

                        [Bool]$FoundArpKey = $true
                    }
                }
            }
            If ( -not $FoundArpKey) {
                If ($Remove) {
                    [String]$Private:Message = "[$Key\$ArpKeyName] not found. `r`nNothing to remove"
                    Write-log -Message $Private:Message -Severity 2 -Source ${CmdletName}
                } ElseIf ($OldParentKeyName) {
                    [String]$Private:Message = "No ParentKeyName set to [$OldParentKeyName] were found. `r`nNothing to Replace/rename"
                    Write-log -Message $Private:Message -Severity 2 -Source ${CmdletName}
                } Else {
                    [String]$Private:Message = "[$Key\$ArpKeyName] not found. `r`nNo Children will be set for the Custom ARP entry. If this is desired, do not call [${CmdletName}] function for this package."
                    Write-log -Message $Private:Message -Severity 3 -Source ${CmdletName}
                    If (-not $ContinueOnError) {
                        throw $Private:Message #this way the packager will definitely see the error before package is released.
                    }
                }
            }
        } Catch {
            [string]$ErrorMessage = "$($_.Exception.Message) $($_.ScriptStackTrace) $($_.Exception.InnerException)"
            Write-Log $ErrorMessage -Severity 3 -Source ${CmdletName}
            Start-Sleep -Seconds 1
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion Function Set-ARPChildOfParent

# TODO region Function Set-LocalDiskUninstall
Function Set-LocalDiskUninstall {
    <#
    .SYNOPSIS
        Creates a local copy of installation files to permit LOCAL uninstallation from a custom ARP entry
    .DESCRIPTION
        Creates a local copy of installation files to permit LOCAL uninstallation from a custom ARP entry
        Copies files from $scriptDirectory (the folder where Deploy-Application.ps1 is) and \SupportFiles\ folder to this local folder
        Creates the $configLocalUninstallCache\$installName folder if not exist
        NOTE: ARP = Add/Remove Programs = Programs and Features = Apps & Features
    .PARAMETER PkgName
        Destination folder name where the installation files will be copied to.	Defaults to $installName
    .PARAMETER Remove
        Removes this folder (for uninstallation)
    .PARAMETER ContinueOnError
        Continue if unable to set or remove values or keys. Default is: $true
    .PARAMETER CopyFilesFolder
        Use to copy the \Files\ folder too. Default is: $false
        Normally we don't need this folder and we can save lots of drive space
    .EXAMPLE
        Set-LocalDiskUninstall
    .EXAMPLE
        Set-LocalDiskUninstall -CopyFilesFolder $true
        Copy the \Files\ folder to $configLocalUninstallCache\$installName too.
        WARNING: You might be copying many GB worth locally just for uninstallation.
    .EXAMPLE
        Set-LocalDiskUninstall -PkgName $installName -Remove
    .NOTES
        Author: Denis St-Pierre (Ottawa, Canada)
        -tested on Windows 10 and Windows 7
        $installName = BaseName of Deploy-Application_v1r1.ps1 file
        \Files\ is not copied by default otherwise there is no difference between \Files\ and \SupportFiles\
        The distinction is needed to save space on the local C: drive
        Only CMD and PS1 files in $scriptDirectory are copied. Place all files needed for uninstall in \SupportFiles\
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = "Name Of Package e.g. 'PkgName_v1r1'")]
        [ValidateNotNullorEmpty()]
        [Alias('FolderName')]
        [string]$PkgName = $installName,
        [Parameter(Mandatory = $false, HelpMessage = "Removes the Local Uninstall folder")]
        [ValidateNotNullorEmpty()]
        [Switch]$Remove = $false,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [boolean]$ContinueOnError = $true,
        [Parameter(Mandatory = $false, HelpMessage = 'Copy the \Files\ folder too.')]
        [ValidateNotNullorEmpty()]
        [boolean]$CopyFilesFolder = $false
    )
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        Try {

            [string]$PKGUNINSTALLDIR = "$configLocalUninstallCache\$PkgName"
            If ($Remove) {
                Write-Log "Removing Local Disk Uninstall Cache [$PKGUNINSTALLDIR]..." -Source ${CmdletName}
                Remove-Folder -Path $PKGUNINSTALLDIR -ContinueOnError $ContinueOnError
                Return #IOW Exit this function
            }

            If ( $PKGUNINSTALLDIR -eq $scriptDirectory ) {
                Write-Log "Running from Local Disk Uninstall Cache, not touching local cache."  -Source ${CmdletName}
            } else {
                Write-Log "Creating Local Disk Uninstall Cache folder [$PKGUNINSTALLDIR]."  -Source ${CmdletName}
                If ( Test-Path -Path "$PKGUNINSTALLDIR" ) {
                    Write-Log "Local Disk Uninstall Cache directory [$PkgName] already exists."  -Source ${CmdletName}
                    Write-Log "Overwriting..."  -Source ${CmdletName}
                }
                Write-Log "Copying files to [$PKGUNINSTALLDIR]..."  -Source ${CmdletName}
                New-Folder -Path $PKGUNINSTALLDIR  -ContinueOnError $ContinueOnError
                Copy-File -Path "$scriptDirectory\*.cmd" -Destination "$PKGUNINSTALLDIR" -ContinueOnError $ContinueOnError
                Copy-File -Path "$scriptDirectory\*.ps1" -Destination "$PKGUNINSTALLDIR" -ContinueOnError $ContinueOnError
                #NOTE: \Files\ is not copied otherwise there is no difference between \Files\ and \SupportFiles\ folders
                If ( Test-Path -Path "$scriptDirectory\SupportFiles") {
                    Copy-File -Path "$scriptDirectory\SupportFiles" -Destination "$PKGUNINSTALLDIR" -Recurse  -ContinueOnError $ContinueOnError
                }
                Copy-File -Path "$scriptDirectory\AppDeployToolkit" -Destination "$PKGUNINSTALLDIR" -Recurse  -ContinueOnError $ContinueOnError
                If ( ( Test-Path -Path "$scriptDirectory\Files") -and $copyFilesFolder ) {
                    Copy-File -Path "$scriptDirectory\Files" -Destination "$PKGUNINSTALLDIR" -Recurse  -ContinueOnError $ContinueOnError
                }
            }

        } Catch {
            [string]$ErrorMessage = "$($_.Exception.Message) $($_.ScriptStackTrace) $($_.Exception.InnerException)"
            Write-Log $ErrorMessage -Severity 3 -Source ${CmdletName}
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion Function Set-LocalDiskUninstall

# TODO region Function Set-ARP_SystemComponent
Function Set-ARP_SystemComponent {
    <#
    .SYNOPSIS
        Hides an ARP entry in the registry
    .DESCRIPTION
        Hides an ARP entry bases on the name of a registry Key in the registry
        Auto-detects if key exists in 32bit or 64bit Registry ARP
        Not meant for MSIs. (Use SYSTEMCOMPONENT=1 MSI property instead)
        NOTE: ARP = Add/Remove Programs = Programs and Features = Apps & Features
    .PARAMETER ArpKeyName
        Name of Registry key (*NOT* full registry path) that we want to hide or unhide
    .PARAMETER Action
        set to 'UnHide' to unhide ARP entry. Omit to hide ARP entry
    .PARAMETER ContinueOnError
        Continue if unable to set or remove values or keys. Default is: $false.
    .EXAMPLE
        ARP_SYSTEMCOMPONENT_HideUnHide "Notepad++" Hide
    .EXAMPLE
        ARP_SYSTEMCOMPONENT_HideUnHide "Notepad++" UnHide
    .EXAMPLE
        ARP_SYSTEMCOMPONENT_HideUnHide "Notepad++" 			(Hide by  default)
    .NOTES
        Author: Denis St-Pierre (Ottawa, Canada)
        -Tested on Windows 10 and Windows 7
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of Registry key (Not full path)")]
        [string]$ArpKeyName,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [ValidateSet("Hide", "UnHide")]
        [string]$Action = "Hide"
    )
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }

    Process {
        Try {
            [string]$HKLMUninstallKey64 = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ArpKeyName"
            [string]$HKLMUninstallKey32 = "HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ArpKeyName"

            #Where is the ARP key? 32 or 64 bit?
            If (Test-Path $HKLMUninstallKey32) {
                If ($Action -ceq "Hide") {
                    Write-Log " Hiding ARP entry [$ArpKeyName] Exists as a 32bit ARP entry" -Source ${CmdletName}
                    Set-RegistryKey -Key $HKLMUninstallKey32 -Name "SystemComponent" -Value 1 -Type DWORD
                } else {
                    Write-Log " Unhiding ARP entry by deleting SystemComponent value [32bit]" -Source ${CmdletName}
                    Remove-RegistryKey -Key $HKLMUninstallKey32 -Name "SystemComponent"
                }
            } else {
                Write-Log " [$ArpKeyName] is NOT a 32bit ARP entry" -Source ${CmdletName}
            }

            If (Test-Path $HKLMUninstallKey64) {
                If ($Action -ceq "Hide") {
                    Write-Log " Hiding ARP entry [$ArpKeyName] Exists as a 64bit ARP entry" -Source ${CmdletName}
                    Set-RegistryKey -Key $HKLMUninstallKey64 -Name "SystemComponent" -Value 1 -Type DWORD
                } else {
                    Write-Log " Unhiding ARP entry by deleting SystemComponent value [64bit]" -Source ${CmdletName}
                    Remove-RegistryKey -Key $HKLMUninstallKey64 -Name "SystemComponent"
                }
            } else {
                Write-Log " [$ArpKeyName] is not a 64bit ARP entry " -Source ${CmdletName}
            }
        } Catch {
            Write-Log -Message "Failed to edit ARP Entry. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion Function Set-ARP_SystemComponent

# TODO region Function Set-ARPNoRemoveNoModifyNoRepair
Function Set-ARPNoRemoveNoModifyNoRepair {
    <#
    .SYNOPSIS
        Sets NoRemove/NoModify/NoRepair values for ARP entry
    .DESCRIPTION
        Sets NoRemove/NoModify/NoRepair values for ARP entry based on the name of the Key in the registry
        Auto-detects if key exists in 32bit or 64bit Registry ARP
        Not meant for MSIs. (Use MSI properties instead)
        NOTE: ARP = Add/Remove Programs = Programs and Features = Apps & Features
    .PARAMETER ArpKeyName
        Name of Registry key (*NOT* full registry path) that we want to affect (Defaults to $InstallName)
    .PARAMETER Action
        set to ONE of the following: NoRemove NoModify NoRepair AllowRemove AllowModify AllowRepair
        CAVEAT: CaSe SenSiTive
    .PARAMETER DeleteAction
        Controls HOW the value is removed
        set to ONE of the following: DeleteValue SetValueToZero
    .EXAMPLE
        Set-ARPNoRemoveNoModifyNoRepair -ArpKeyName "Notepad++" -Action NoRemove
        Hides [Remove] button in ARP by creating/setting the NoRemove value 1
    .EXAMPLE
        Set-ARPNoRemoveNoModifyNoRepair -ArpKeyName "Notepad++" -Action AllowRemove
        Deletes the NoRemove value to enable [Remove] button in ARP
    .EXAMPLE
        Set-ARPNoRemoveNoModifyNoRepair -ArpKeyName "Notepad++" -Action AllowRemove -DeleteAction 'SetValueToZero'
        Same as above but Sets the NoRemove value to '0' instead of deleting the NoRemove value
    .EXAMPLE
        Set-ARPNoRemoveNoModifyNoRepair -Action NoRemove
        Hides [Remove] or [Uninstall] button in ARP for $InstallName
    .EXAMPLE
        Set-ARPNoRemoveNoModifyNoRepair -ArpKeyName 'ProPlus2019Volume - en-us' -Action NoRemove
        Set-ARPNoRemoveNoModifyNoRepair -ArpKeyName 'ProPlus2019Volume - en-us' -Action AllowRemove
        Set-ARPNoRemoveNoModifyNoRepair -ArpKeyName 'ProPlus2019Volume - en-us' -Action AllowRemove -DeleteAction SetValueToZero
    .NOTES
        Author: Denis St-Pierre (Ottawa, Canada)
        -Tested on Windows 10 and Windows 7
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of Registry key (Not full path)")]
        [string]$ArpKeyName,
        [Parameter(Mandatory = $true, HelpMessage = "Set to ONE of the following: NoRemove NoModify NoRepair AllowRemove AllowModify AllowRepair")]
        [ValidateNotNullorEmpty()]
        [ValidateSet('NoRemove', 'NoModify', 'NoRepair', 'AllowRemove', 'AllowModify', 'AllowRepair', IgnoreCase = $false)]
        [string]$Action = "",
        [Parameter(Mandatory = $false, HelpMessage = "Set to ONE of the following: DeleteValue SetValueToZero. DeleteValue is the default" )]
        [ValidateNotNullorEmpty()]
        [ValidateSet('DeleteValue', 'SetValueToZero')]
        [string]$DeleteAction = "DeleteValue"
    )
    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }

    Process {
        Try {
            [string]$HKLMUninstallKey64 = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ArpKeyName"
            [string]$HKLMUninstallKey32 = "HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ArpKeyName"

            #Where is the ARP key? 32 or 64 bit?
            If (Test-Path -LiteralPath $HKLMUninstallKey32) {
                If ($Action -like "No*") {
                    Write-Log " Setting [$Action] for ARP entry [$ArpKeyName] Exists as a 32bit ARP entry" -Source ${CmdletName}
                    Set-RegistryKey -Key $HKLMUninstallKey32 -Name $Action -Value 1 -Type DWORD
                } ElseIf ($Action -like "Allow*") {
                    [String]$ActualValueName = $Action.replace("Allow", "No")
                    If ($DeleteAction -eq 'DeleteValue') {
                        Write-Log " Deleting [$ActualValueName] for ARP entry [$ArpKeyName] Exists as a 32bit ARP entry" -Source ${CmdletName}
                        Remove-RegistryKey -Key $HKLMUninstallKey32 -Name $ActualValueName
                    } ElseIf ($DeleteAction -eq 'SetValueToZero') {
                        Write-Log " Setting Value [$ActualValueName] to 0 for ARP entry [$ArpKeyName] Exists as a 32bit ARP entry" -Source ${CmdletName}
                        Set-RegistryKey -Key $HKLMUninstallKey32 -Name $ActualValueName -Value 0 -Type DWORD
                    } Else {
                        Write-Log "`$DeleteAction = [$DeleteAction] is not handled by this function" -Source ${CmdletName} -Severity 2
                    }
                } Else {
                    Write-Log "`$Action = [$Action] is not handled by this function" -Source ${CmdletName} -Severity 2
                }
            } Else {
                Write-Log " [$ArpKeyName] is NOT a 32bit ARP entry" -Source ${CmdletName}
            }

            If (Test-Path -LiteralPath $HKLMUninstallKey64) {
                If ($Action -like "No*") {
                    Write-Log " Setting [$Action] for ARP entry [$ArpKeyName] Exists as a 64bit ARP entry" -Source ${CmdletName}
                    Set-RegistryKey -Key $HKLMUninstallKey64 -Name $Action -Value 1 -Type DWORD
                } ElseIf ($Action -like "Allow*") {
                    [String]$ActualValueName = $Action.replace("Allow", "No")
                    If ($DeleteAction -eq 'DeleteValue') {
                        Write-Log " Deleting [$ActualValueName] for ARP entry [$ArpKeyName] Exists as a 64bit ARP entry" -Source ${CmdletName}
                        Remove-RegistryKey -Key $HKLMUninstallKey64 -Name $ActualValueName
                    } ElseIf ($DeleteAction -eq 'SetValueToZero') {
                        Write-Log " Setting Value [$ActualValueName] to 0 for ARP entry [$ArpKeyName] Exists as a 64bit ARP entry" -Source ${CmdletName}
                        Set-RegistryKey -Key $HKLMUninstallKey64 -Name $ActualValueName -Value 0 -Type DWORD
                    } Else {
                        Write-Log "`$DeleteAction = [$DeleteAction] is not handled by this function" -Source ${CmdletName} -Severity 2
                    }
                } Else {
                    Write-Log " [$Action] is not handled by this function" -Source ${CmdletName} -Severity 2
                }
            } Else {
                Write-Log " [$ArpKeyName] is NOT a 64bit ARP entry " -Source ${CmdletName}
            }
        } Catch {
            Write-Log -Message "Failed to edit ARP Entry. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion Function Set-ARPNoRemoveNoModifyNoRepair

# TODO Add more functions just above this line

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================
#Local cache location of PSADT file --> NO SPACES in the path!!!
[String]$configLocalUninstallCache = "$envProgramFiles\PSADT\uninstall"

If ($scriptParentPath) {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
