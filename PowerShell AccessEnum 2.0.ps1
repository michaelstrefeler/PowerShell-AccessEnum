  <#
    .SYNOPSIS
      PowerShell script to compare folder permissions
    .DESCRIPTION
      This script is used to compare file permissions between a parent folder and it's subfolders. The script lists added users, missing users and different user permissions.
    .EXAMPLE
       '.\PowerShell AccessEnum 2.0.ps1' -path \\enac1files.epfl.ch\ENAC-IT\IT2 -depth 5
       This command will compare the permissions of all subfolders 5 levels into the path (\\enac1files.epfl.ch\ENAC-IT\IT2\1\2\3\4\5)
    .EXAMPLE
       '.\PowerShell AccessEnum 2.0.ps1' -path \\?\UNC\enac1files.epfl.ch\ENAC-IT\common\testLongpath
       For long paths you need to write \\?UNC\ before the path. -depth is an optional parameter. If it is not provided the script will go though all of the subfolders in the path
  #>

param (
    [Parameter(Mandatory=$True)]
    [string]$path,   

    [Parameter(Mandatory=$False)]
    $depth
 )


# While $path was isn't correct
while(-not $path -or $path -notmatch '^(?![\s]).*' -or $path -match '\w:\\$' -or -not (Test-Path $path)){
    #$path = $( Read-Host "Enter a valid path " )
    if(-not $path){
        $path = $( Read-Host "The previous path was empty. Enter a valid path " )
    }
    if($path -notmatch '^(?![\s]).*'){
        $path = $( Read-Host "The previous path started with a space. Enter a valid path " )
    }
    if($path -match '\w:\\$'){
        $path = $( Read-Host "Root folders like 'C:\' are unsupported. Enter a different path " )
    }
    if(-not (Test-Path $path)){
        $path = $( Read-Host "The previous path was incorrect enter a valid one this time " )
    }
}


<#$theQuestion = $( Read-Host "Do you want to go through all of the subfolders? Y/N ")

while($theQuestion -ine "Y" -and $theQuestion -ine "N"){
    $theQuestion = $( Read-Host "Please answer Y for Yes or N for No")
}

#>

$newPath = $path
$userPath = $newPath

<#
    Function used to check is permissions are the same between a parent folder and a child folder
    $userPath is used to dynamically go through subfolders
#>

function checkForDifferences($userPath){
    # Variable declaration
    $parentPath = $userPath | Split-Path -Parent
    $currentFolder =  Get-Acl $userPath
    $parentFolder = Get-Acl $parentPath 

    # Arrays for storing info about current folder ACL
    $cUsers = @()
    $cFSR = @()
    $cInherited = @()

    # Arrays for storing info about parent folder ACL
    $pUsers = @()
    $pFSR = @()
    $pInherited = @()

    # Foreach used to store the currrent folder's Access properties in arrays
    ForEach ($item in $currentFolder) {

        $currentAccess = $item | Select-Object -ExpandProperty Access

            ForEach ($accessRight in $currentAccess){
                $cUsers += ,$accessRight.IdentityReference
                $cFSR += ,$accessRight.FileSystemRights
                $cInherited += ,$accessRight.IsInherited
            }
    }

    # Foreach used to store the parent folder's Access properties in arrays
    ForEach ($item in $parentFolder) {

        $parentFolder = $item | Select-Object -ExpandProperty Access
       
            ForEach ($accessRight in $parentFolder){
                $pUsers += ,$accessRight.IdentityReference 
                $pFSR += ,$accessRight.FileSystemRights
                $pInherited += ,$accessRight.IsInherited
            }
    }

    <#
        Missing users shows users that have permisisons in the parent folder but not the child
        Added users shows the users that have permissions in the child folder but not the parent
    #>
    $missingUsers = $pUsers | Where {$cUsers -notcontains $_}
    $addedUsers = $cUsers | Where {$pUsers -notcontains $_}
    $changedPermissions = $pUsers | Where {$cUsers -contains $_}


    $index = 0
    # Lists Users whose permissions have changed
    foreach ($user in $pUsers){
        if($pFSR[$index] -ne $cFSR[$index] -and $pInherited[$index] -eq $cInherited[$index]){
            Write-Host ""
            Write-Host $user " permissions in "$userPath -ForegroundColor Yellow
            Write-Host $cFSR[$index] -ForegroundColor Yellow
        }

        $index++
    }

    # Lists missing users if there are any and if there aren't any added users
    if($missingUsers -ne $null -and $addedUsers -eq $null){
        Write-Host "`nUser differences in $userPath"
        Write-Host "`nUsers missing from current folder`n$missingUsers" -ForegroundColor Red
    }

    # Lists added users if there are any and if there aren't any missing users
    if($addedusers -ne $null -and $missingUsers -eq $null){
         Write-Host "`nUser differences in $userPath"
         Write-Host "`nUsers added to current folder`n$addedusers" -ForegroundColor Green
         $index = 0

         # Loops through the list of current users and lists the permissions of any added users
         foreach($user in $cUsers){
            if($user -eq $addedUsers){
                Write-Host "`n$user's permissions:"
                Write-Host $cFSR[$index]
                Write-Host "Inherited:"$cInherited[$index]
            }else{
                $index++
            }
        }
    }

    # Lists missing users and added users
    if($missingUsers -ne $null -and $addedusers -ne $null){
        Write-Host "`nUser differences in $userPath"
        Write-Host "`nUsers missing from current folder`n$missingUsers" -ForegroundColor Red
        Write-Host "`nUsers added to current folder`n$addedUsers" -ForegroundColor Green
         $index = 0
         foreach($user in $cUsers){
            if($user -eq $addedUsers){
                Write-Host "`n$user's permissions:"
                Write-Host $cFSR[$index]
                Write-Host "Inherited:"$cInherited[$index]
            }else{
                $index++
            }
        }

    }

    # Checks if permissions are the same and writes all persmissions are the same if so
    if($addedusers -eq $null -and $missingUsers -eq $null){
        Write-Host "`nAll the permissions are the same in $userPath" -ForegroundColor Green
    }

    $newPath = $currentFolder
}

Write-Host "Here are the results for"$path 
Write-Host "This may take a while"

if($depth){
    # Calling function to list differnces between parent folder and child folder
    # checkForDifferences($newPath)

    $childFolders = ls $userPath -Directory -Name -Depth ($depth-1)
    
    # Foreach loop for going through all subfolders in the user input
    foreach($child in $childFolders){
        # Calling function to list differences in subfolders 
        checkForDifferences(Join-Path -Path $path -ChildPath $child)
    }
   


}else{
    # Calling function to list differnces between parent folder and child folder
    checkForDifferences($newPath)

    $childFolders = ls $userPath -Directory -Recurse -Name

    # Foreach loop for going through all subfolders in the user input
    foreach($child in $childFolders){

        # Calling function to list differences between 
        checkForDifferences(Join-Path -Path $path -ChildPath $child)
    }
}



Read-Host -Prompt "`n`nPress Enter to exit" 

# C:\Users\mstrefel\test <-- Different persmissions
# \\?\UNC\enac1files.epfl.ch\ENAC-IT\common\testLongpath <-- Long path