function Copy-GitRepository {
<#
.SYNOPSIS
    Clones a Git repository to a specified destination folder, with optional renaming.

.DESCRIPTION
    This function clones a Git repository from a specified source to a destination folder.
    If the destination folder already exists and has a folder with the same name as the repository,
    it appends a sequential number to the folder name.
    Optionally, it allows the user to rename the repository folder.

.PARAMETER repoPath
    The URL or path of the Git repository to clone.

.PARAMETER destFolder
    The destination folder where the repository will be cloned. If not provided, the user will be prompted.

.PARAMETER newFolderName
    Optional. The new name for the repository folder. If not provided, the user will be prompted.

.EXAMPLE
    Copy-GitRepository -repoPath "https://github.com/example/repo.git" -destFolder "C:\Projects" -newFolderName "new_repo"
#>

    param(
        [Parameter(Mandatory = $true)]
        [string]$repoPath,
        [Parameter(Mandatory = $false)]
        [string]$destFolder,
        [Parameter(Mandatory = $false)]
        [string]$newFolderName
    )

    # If destination folder is not provided, prompt the user
    if (-not $destFolder) {
        $destFolder = Read-Host 'Enter the destination folder'
    }

    # If new folder name is not provided, prompt the user
    if (-not $newFolderName) {
        $renameRepo = Read-Host 'Do you want to rename the repository folder? (Y/N)'
        if ($renameRepo -eq 'Y' -or $renameRepo -eq 'y') {
            $newFolderName = Read-Host 'Enter the new repository folder name'
        }
    }

    # Check if destination folder already exists
    if (Test-Path $destFolder) {
        # If the destination folder already has a folder with the same name, append a sequential number
        $i                  = 1
        $baseRepoFolderName = $(Split-Path -Leaf $repoPath)
        $newRepoFolder      = Join-Path -Path $destFolder -ChildPath ($baseRepoFolderName + "_$i")
        while (Test-Path $newRepoFolder) {
            $i++
            $newRepoFolder = Join-Path -Path $destFolder -ChildPath ($baseRepoFolderName + "_$i")
        }
    } else {
        # If the destination folder does not exist, create it
        New-Item -Path $destFolder -ItemType Directory -Force | Out-Null -Verbose
        $newRepoFolder = Join-Path -Path $destFolder -ChildPath $(Split-Path -Leaf $repoPath)
    }

    # Clone the git repository
    git clone $repoPath $newRepoFolder | Out-Host

    # If a new folder name was provided, rename the folder
    if ($newFolderName) {
        Rename-Item -Path $newRepoFolder -NewName $newFolderName -Force -Verbose
        $newRepoFolder = Join-Path -Path $destFolder -ChildPath $newFolderName
    }
}

Copy-GitRepository -repoPath 'E:\DevOps\PSADT-Master\PSAppDeployToolkit' -destFolder 'E:\DevOps\PSADT-Projects'
