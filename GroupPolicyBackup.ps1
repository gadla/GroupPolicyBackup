<#
.SYNOPSIS
    This script backs up all Group Policy Objects (GPOs) and their associated WMI Filters to a specified location.

.DESCRIPTION
    The script accepts a mandatory parameter for the backup path. It validates the path to ensure it exists and is a directory. For each execution, the script creates a new folder named with the current date in the "YYYY-MM-DD" format under the specified backup path. Each GPO is backed up in a separate subfolder named after the GPO within the daily backup folder. The script generates an HTML report for each GPO and saves it within the respective GPO's backup folder. Additionally, the script backs up all WMI Filters into a subfolder named "WMI_Filters" within the daily backup folder.

.PARAMETER BackupPath
    The path to the directory where backups will be stored. This parameter is mandatory, and the script validates that the path exists and is a directory before proceeding with the backups.

.EXAMPLE
    .\GroupPolicyBackup.ps1 -BackupPath "C:\GPOBackups" -DaysToKeep 30
    This example runs the script with the backup path set to "C:\GPOBackups". The script will create a new folder under "C:\GPOBackups" with the current date and store all GPO and WMI Filter backups inside it.
    The script will also delete any backup folders older than 30 days from the backup path.

.NOTES
    Author: Gadi Lev-Ari
    This script requires Group Policy and Active Directory PowerShell modules. Ensure you have the necessary permissions to access GPOs, WMI Filters, and the backup location.

.LINK
    https://github.com/gadla/GroupPolicyBackup.git
#>
#Requires -Modules ActiveDirectory

param(
    [Parameter(Mandatory = $true,
        HelpMessage = "Enter the full path of the directory where you want to store the GPO and WMI filters backup. The path must exist.")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$BackupPath,

    [Parameter(Mandatory = $false, HelpMessage = "Enter the number of days of backups to keep. Older backups will be deleted.")]
    [int]$DaysToKeep = 30
)

# Function to delete old backup folders
function Remove-OldBackups {
    <#
    .SYNOPSIS
        Removes backup folders older than a specified number of days from a given root backup directory.

    .DESCRIPTION
        This function iterates through all subdirectories of a specified root backup directory and deletes those that are older than a given number of days. The age of a backup folder is determined by parsing its name, which is expected to be in the 'yyyy-MM-dd' format. This function is useful for maintaining a clean backup directory by automatically removing outdated backups.

    .PARAMETER BackupRootPath
        The full path to the root directory containing the backup folders. This path must exist and be a valid directory. Each backup folder within this directory should be named according to the date it was created, in 'yyyy-MM-dd' format.

    .PARAMETER RetentionDays
        The number of days for which backups should be retained. Backup folders older than this number of days will be deleted. This parameter helps manage disk space by ensuring only recent backups are kept.

    .EXAMPLE
        Remove-OldBackups -BackupRootPath "C:\Backups" -RetentionDays 30
        This example will delete all backup folders within "C:\Backups" that are older than 30 days.

    .NOTES
        It's important to ensure that the backup folder names strictly follow the 'yyyy-MM-dd' format for this function to correctly identify and delete old backups. If a folder name cannot be parsed into a date, the function will log a warning and skip that folder.

        Use this function with caution, as it will permanently delete data. Ensure that you have adequate backups and have verified the folder naming convention before using it in a production environment.

    #>
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Enter the full path of the directory where you want to store the GPO and WMI filters backup. The path must exist.")]
        [ValidateScript({ Test-DeletePermission -Path $_ })]
        [string]$BackupRootPath, # The root path where all backups are stored.

        [int]$RetentionDays # The number of days to retain backups. Folders older than this will be deleted.
    )

    # Get all subdirectories in the backup root path.
    $BackupFolders = Get-ChildItem -Path $BackupRootPath -Directory

    foreach ($Folder in $BackupFolders) {
        try {
            # Attempt to parse the folder name as a date assuming the folder name is in 'yyyy-MM-dd' format.
            $FolderDate = [DateTime]::ParseExact($Folder.Name, "yyyy-MM-dd", $null)

            # Calculate how old the folder is in days.
            $AgeInDays = (Get-Date) - $FolderDate

            # If the folder is older than the specified retention period, it will be deleted.
            if ($AgeInDays.Days -gt $RetentionDays) {
                Write-Host "Deleting old backup folder: $($Folder.FullName) (Age: $($AgeInDays.Days) days)"
                # Remove the folder and all contents forcefully.
                Remove-Item -Path $Folder.FullName -Recurse -Force
            }
        }
        catch {
            # If an error occurs (e.g., the folder name cannot be parsed as a date), log the error and continue.
            Write-Warning "Could not process folder '$($Folder.Name)': $_"
        }
    }
}

# Function to backup a single GPO
function Backup-GPOFunction {
    <#
    .SYNOPSIS
        Backs up a specified Group Policy Object (GPO) and generates an HTML report in the target directory.

    .DESCRIPTION
        This function takes the name of a GPO and a target path as inputs. It performs a backup of the specified GPO into the target directory and generates an HTML report of the GPO in the same location. The function uses the 'Backup-GPO' cmdlet to create the backup and 'Get-GPOReport' cmdlet to generate the report.

    .PARAMETER GPOName
        The name of the Group Policy Object (GPO) that you want to back up. The GPO must exist in the Active Directory domain that the script is being run against.

    .PARAMETER TargetPath
        The file system path where the GPO backup and HTML report will be stored. The path must exist and be writable by the user running the script.

    .EXAMPLE
        Backup-GPOFunction -GPOName "Default Domain Policy" -TargetPath "C:\GPOBackups\2021-01-01"
        This example backs up the "Default Domain Policy" GPO into the specified directory and generates an HTML report of the GPO in the same directory.

    .NOTES
        Ensure that the 'GroupPolicy' and 'ActiveDirectory' PowerShell modules are installed and available, as this function relies on cmdlets from these modules.
        Running this function requires appropriate permissions to access and back up the specified GPO.
    #>
    param(
        [string]$GPOName,
        [string]$TargetPath
    )

    $GPO = Get-GPO -Name $GPOName
    $BackupId = Backup-GPO -Guid $GPO.Id -Path $TargetPath
    Get-GPOReport -Guid $GPO.Id -ReportType Html -Path "$TargetPath\GPOReport.html"
    Write-Host "Backup and report for GPO '$GPOName' completed."
}


# Function to test if the current user has delete permission on a given path
function Test-DeletePermission {
    <#
    .SYNOPSIS
        Tests if the current user has delete permission on a given path.

    .DESCRIPTION
        The Test-DeletePermission function checks if the current user has delete permission on the specified path. It uses the Get-Acl cmdlet to get the Access Control List (ACL) of the path and then checks if the current user has delete permission.

    .PARAMETER Path
        Specifies the path to test delete permission. This parameter is mandatory.

    .EXAMPLE
        PS C:\> Test-DeletePermission -Path "C:\SomeFolder"
        This command tests if the current user has delete permission on the folder "C:\SomeFolder".

    .INPUTS
        System.String. You can pipe a string that contains the path.

    .OUTPUTS
        System.Boolean. The function returns $true if the current user has delete permission, otherwise it returns $false.

    .NOTES
        In case of any errors (like path not found), the function writes a warning and returns $false.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $hasDeletePermission = $false

    # Check if the path exists and is accessible
    if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
        Write-Warning "Path $Path does not exist or is not accessible."
        return $false
    }

    try {
        # Get the security descriptor for the folder
        $acl = Get-Acl -Path $Path

        # Get the current user and their groups
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $currentUserSid = $currentUser.User.Value
        $groupSids = $currentUser.Groups | Select-Object -ExpandProperty Value

        # Check if the user has modify (which includes delete) or full control permission
        foreach ($access in $acl.Access) {
            if (($access.FileSystemRights -match 'Modify' -or $access.FileSystemRights -match 'FullControl') -and 
                ($currentUserSid -eq $access.IdentityReference.Value -or $groupSids -contains $access.IdentityReference.Value)) {
                $hasDeletePermission = $true
                break
            }
        }

        # Additionally check if the user is an administrator
        $isAdmin = ([System.Security.Principal.WindowsPrincipal]$currentUser).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) {
            $hasDeletePermission = $true
        }
    }
    catch {
        Write-Warning "Unable to get ACL for path $Path : $_"
    }

    return $hasDeletePermission
}



# Create a new folder with the current date
$DateFolder = Get-Date -Format "yyyy-MM-dd"
$DailyBackupPath = Join-Path -Path $BackupPath -ChildPath $DateFolder
New-Item -Path $DailyBackupPath -ItemType Directory -Force | Out-Null

# Backup all GPOs
$GPOs = Get-GPO -All
foreach ($GPO in $GPOs) {
    $GPOPath = Join-Path -Path $DailyBackupPath -ChildPath $GPO.DisplayName
    New-Item -Path $GPOPath -ItemType Directory -Force | Out-Null
    Backup-GPOFunction -GPOName $GPO.DisplayName -TargetPath $GPOPath
}

# Backup WMI Filters
$WMIPath = Join-Path -Path $DailyBackupPath -ChildPath "WMI_Filters"
New-Item -Path $WMIPath -ItemType Directory -Force | Out-Null
# Get the WMI filters from Active Directory
$WmiFilters = Get-ADObject -Filter 'objectClass -eq "msWMI-Som"' -Properties msWMI-Author, msWMI-ID, msWMI-Name, msWMI-Parm1, msWMI-Parm2
if ($null -ne $WmiFilters) {
    Write-Host "Backing up $($WmiFilters.Count) WMI filters."
    if ($WmiFilters -is 'System.Object[]') {
        # Loop through each filter and export it to a file
        foreach ($filter in $WmiFilters) {
            $filter | Export-Clixml -Path "$WMIPath\$($filter.'msWMI-Name').xml"
        }
    }
    else {
        $WmiFilters | Export-Clixml -Path "$WMIPath\$($WmiFilters.'msWMI-Name').xml"
    }
    Write-Host "WMI Filters backed up to '$WMIPath'."
}
else {
    Write-Host "No WMI filters found."
}

Write-Host "Removing old backups older than $DaysToKeep days."
Remove-OldBackups -BackupRootPath $BackupPath -RetentionDays $DaysToKeep