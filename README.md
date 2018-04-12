# AccesEnum PowerShell

> A PowerShell script used to compare folder's permissions with it's subfolders' permissions.

## Usage

To run the script open the CMD to the folder that the script is in and type:
start powershell -command "& '.\PowerShell AccessEnum 2.0.ps1' -path <Your Path Here> -depth <Number of subfolders you want to go through>

For example start powershell -command "& '.\PowerShell AccessEnum 2.0.ps1' -path \\enac1files.epfl.ch\ENAC-IT\IT2 -depth 5
This command will compare the permissions of all subfolders 5 levels into the path (\\enac1files.epfl.ch\ENAC-IT\IT2\1\2\3\4\5)

The depth parameter can be removed if you want to go through all of the subfolders

Get-Help .\PowerShell AccessEnum 2.0.ps1' -Detailed 
Can be used to get useful information about the script
