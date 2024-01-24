# Group Policy Backup

This script, `GroupPolicyBackup.ps1`, is designed to backup Group Policy objects (GPOs) in a Windows environment. It allows you to easily create backups of your GPOs, providing an extra layer of protection against accidental changes or deletions.

## Prerequisites

Before using this script, ensure that you have the following:

- Windows PowerShell installed on your system.
- Sufficient permissions to access and modify Group Policy objects.

## Usage

To use the `GroupPolicyBackup.ps1` script, follow these steps:

1. Open a PowerShell console or the PowerShell Integrated Scripting Environment (ISE).
2. Navigate to the directory where the script is located.
3. Run the script by executing the following command:

    ```powershell
    .\GroupPolicyBackup.ps1
    ```

4. The script will prompt you to specify the backup destination folder. Enter the desired path and press Enter.
5. The script will then proceed to backup all GPOs in your environment to the specified folder.

## Backup Folder Structure

The script creates a folder structure within the specified backup destination folder to organize the GPO backups. The structure is as follows:
