# Group Policy Objects (GPO) Backup Script

This PowerShell script is designed to back up all Group Policy Objects (GPOs) and their associated WMI Filters to a specified location. Each backup is organized into a folder named with the current date, and each GPO is saved in its individual subfolder within the daily backup folder. An HTML report for each GPO is also generated and stored in its respective backup folder.

## Features

- **Backup GPOs:** Each GPO is backed up into its own subfolder within a daily backup folder.
- **Backup WMI Filters:** All WMI Filters are backed up into a subfolder named "WMI_Filters" within the daily backup folder.
- **HTML Reports:** Generates an HTML report for each GPO and stores it within the GPO's backup folder.
- **Automatic Cleanup:** Deletes backup folders older than a specified number of days to manage disk space.

## Prerequisites

- PowerShell 5.1 or higher.
- Group Policy and Active Directory PowerShell modules.
- Necessary permissions to access GPOs, WMI Filters, and the backup location.

## Parameters

- `BackupPath`: Mandatory. The path to the directory where backups will be stored. The script validates that the path exists and is a directory.
- `DaysToKeep`: Optional. Specifies the number of days backups should be retained. Older backups will be deleted. Default is 30 days.

## Usage

Run the script with the required `BackupPath` parameter and the optional `DaysToKeep` parameter. For example:

```powershell
.\GroupPolicyBackup.ps1 -BackupPath "C:\GPOBackups" -DaysToKeep 30
