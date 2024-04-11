# Vars
. ".vscode\Global.ps1"

# intunewin
[string]$Uri = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/tree/master"
[string]$Exe = "IntuneWinAppUtil.exe"

# Source content prep tool
if (-not(Test-Path -Path "$env:ProgramData\$Exe")){
    Invoke-WebRequest -Uri "$Uri/$Exe" -OutFile "$env:ProgramData\$Exe"
}

# Execute content prep tool
$processOptions = @{
    FilePath = "$env:ProgramData\$Exe"
    ArgumentList  = "-c ""$Cache"" -s ""$Cache\Deploy-Application.exe"" -o ""$env:TEMP"" -q"
    WindowStyle = "Maximized"
    Wait = $true
}
Start-Process @processOptions

# Rename and prepare for upload
mkdir $Repo\$Application
Copy-Item -Path "$Cache" -Destination "$Repo" -Container -Recurse -Force -Verbose -ErrorAction Ignore
Move-Item -Path "$env:TEMP\Deploy-Application.intunewin" -Destination "$Repo\$Application\$Application.intunewin" -Force -Verbose

explorer $Repo
