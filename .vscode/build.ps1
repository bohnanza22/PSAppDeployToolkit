# Vars
# dotsource the Global.ps1 file to bring in global variables
. '.vscode\Global.ps1'

# Copy Cache
Remove-Item -Path "$Cache" -Recurse -Force -ErrorAction Ignore
Copy-Item -Path 'Toolkit' -Destination "$Cache" -Recurse -Force -Verbose -ErrorAction Ignore

# intunewin
#[string]$Uri = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/tree/master" # This URL wasn't downloading the right file
[string]$Uri = 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master'
[string]$Exe = 'IntuneWinAppUtil.exe'

# Source content prep tool
if (-not(Test-Path -Path "$env:ProgramData\$Exe")) {
    Invoke-WebRequest -Uri "$Uri/$Exe" -OutFile "$env:ProgramData\$Exe" -Verbose
}

# Remove old package build directory
if (Test-Path -Path "$Repo\$Application") {
    Remove-Item -Path "$Repo\$Application" -Recurse -Force -Verbose -ErrorAction Continue
}

# Creates the new folder to recieve the package files
New-Item -Path "$Repo\$Application" -ItemType 'Directory' -Force -Verbose -ErrorAction Continue

# Test if Deploy-Application.exe exists in the $cache and execute the InTune Prep Tool
if (Test-Path -Path "$Cach\Deploy-Application.exe") {
    # Execute content prep tool
    $processOptions = @{
        FilePath     = "$env:ProgramData\$Exe"
        ArgumentList = "-c ""$Cache"" -s ""$Cache\Deploy-Application.exe"" -o ""$env:TEMP"" -q"
        WindowStyle  = 'Maximized'
        Wait         = $true
        Verbose      = $true
    }
    Start-Process @processOptions

    # Rename and move the InTune package file to the Package build Folder
    Move-Item -Path "$env:TEMP\Deploy-Application.intunewin" -Destination "$Repo\$Application\$Application.intunewin" -Force -Verbose
}

Copy-Item -Path "$Cache" -Destination "$Repo" -Container -Recurse -Force -Verbose -ErrorAction Ignore

explorer $Repo
