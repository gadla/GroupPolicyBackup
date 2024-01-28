# Group Policy Objects (GPO) Backup Script

This PowerShell script efficiently backs up all Group Policy Objects (GPOs) and their associated WMI Filters to a specified location. It's an essential tool for system administrators and IT professionals to ensure the safety and recoverability of GPOs.

## Features

- **Individual GPO Backups**: Each GPO is backed up into its own subfolder within a daily dated folder.
- **WMI Filters Backup**: All WMI Filters are saved in a "WMI_Filters" subfolder.
- **HTML Reports**: For each GPO, the script generates an HTML report and stores it with the backup.
- **Automatic Cleanup**: Manages disk space by deleting backups older than a specified number of days.


## Prerequisites

- PowerShell 5.1 or higher.
- Group Policy and Active Directory PowerShell modules installed.
- Appropriate permissions to access GPOs, WMI Filters, and the specified backup location.

## Parameters

- `BackupPath` (Mandatory): Path to the directory where backups will be stored (e.g., `"C:\GPOBackups"`).
- `DaysToKeep` (Optional): Number of days to retain backups. Defaults to 30 days.

## Usage

Run the script with the necessary parameters. Example:

```powershell
.\GroupPolicyBackup.ps1 -BackupPath "C:\GPOBackups" -DaysToKeep 30
