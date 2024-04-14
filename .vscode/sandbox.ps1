# Vars
# dotsource the Global.ps1 file to bring in global variables
. '.vscode\Global.ps1'

# Copy Cache
Remove-Item -Path "$Cache" -Recurse -Force -ErrorAction Ignore
Copy-Item -Path 'Toolkit' -Destination "$Cache" -Recurse -Force -Verbose -ErrorAction Ignore

# Reset Resources
Remove-Item -Path "$Resources" -Recurse -Force -ErrorAction Ignore
New-Item -Path "$Resources" -ItemType Directory -Force -Verbose -ErrorAction Ignore

# Copy Bootstrap.ps1
Copy-Item -Path ".vscode\$LogonCommand" -Destination "$Resources" -Recurse -Force -Verbose -ErrorAction Ignore

# Copy CMTrace to the Sandbox Env.
$cmTracePth = "$env:Windir\CCM\CMTrace.exe"
if (Test-Path -Path $cmTracePth) {
    Write-Host "$env:Windir\CCM\CMTrace.exe exists."
    Copy-Item -Path $cmTracePth -Destination "$Resources" -Force -Verbose -ErrorAction Ignore
}

$tstWSBRes = Get-ChildItem -Path $wsbResources -Force
# Copy Wallpaper to the Sandbox Env.
if ($tstWSBRes -ne $null) {
    Write-Host "$wsbResources is not empty."
    Copy-Item -Path "$wsbResources\*" -Destination "$Resources" -Force -Verbose -ErrorAction Ignore
}

# Prepare Sandbox
@"
<Configuration>
<Networking>Enabled</Networking>
<vGPU>Enable</vGPU>
<ClipboardRedirection>value</ClipboardRedirection>
<MappedFolders>
    <MappedFolder>
    <HostFolder>$Win32App\$Application</HostFolder>
    <SandboxFolder>$WDADesktop\$Application</SandboxFolder>
    <ReadOnly>true</ReadOnly>
    </MappedFolder>
    <MappedFolder>
    <HostFolder>$Resources</HostFolder>
    <SandboxFolder>$env:SystemDrive\Resources</SandboxFolder>
    <ReadOnly>true</ReadOnly>
    </MappedFolder>
</MappedFolders>
<LogonCommand>
    <Command>powershell -executionpolicy unrestricted -command "Start-Process powershell -ArgumentList '-nologo -file $env:SystemDrive\Resources\$LogonCommand -Application $Application'"</Command>
</LogonCommand>
</Configuration>
"@ | Out-File "$Resources\$Application.wsb"

# Execute Sandbox

Start-Sleep -Seconds 3
# Wait until Windows Sandbox process has exited.

Start-Process explorer -ArgumentList "$Resources\$Application.wsb" -Verbose
# Wait for Windows Sandbox to start.
$processName = 'WindowsSandbox'
$sandboxProc = Get-Process -Name WindowsSandbox -Verbose -ErrorAction Ignore
while ($sandboxProc -eq $null) {
    Write-Host "$processName has NOT started..."
    Start-Sleep -Seconds 3
    $sandboxProc = Get-Process -Name $processName -Verbose
}
Write-Host "$processName has started."

# Wait for Windows Sandbox to exit
while ($sandboxProc.HasExited -eq $false) {
    Start-Sleep -Seconds 3

}

# Cleanup Sandbox settings and test files
Remove-Item -Path "$Win32App\*" -Recurse -Force -Verbose -ErrorAction Continue
