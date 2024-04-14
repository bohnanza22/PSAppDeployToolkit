# This script clears the build and test cache of any folders and files.

[string]$csh = "$env:ProgramData\win32app"

Remove-Item -Path "$csh\*" -Recurse -Force -Verbose -ErrorAction Continue
