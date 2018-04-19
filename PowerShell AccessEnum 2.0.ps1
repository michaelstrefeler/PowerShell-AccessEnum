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

# Variable declaration
$newPath = $path
$userPath = $newPath
$global:outputArray = @()

<#
    Function used to check is permissions are the same between a parent folder and a child folder
    $userPath is used to dynamically go through subfolders
#>

$x = 1
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



    if($addedusers -eq $null -and $missingUsers -eq $null){
       # Do Nothing
    }else{
        $global:outputArray += [PSCustomObject]@{"Path" = "$userPath"; "Read" = ""; "Write" = ""; "Modify" =""; "FullControl" = ""}
        foreach($user in $addedUsers){
            $i = [array]::indexof($cUsers,$user)
            $cFSR[$i]
            
            if($cFSR[$i] -like '*Read*'){
                if($global:outputArray[$x].Read -eq ""){
                    $global:outputArray[$x].Read += $user
                }else{
                    $global:outputArray[$x].Read += ","+$user
                }
            }

            if($cFSR[$i] -like '*Write*'){
                if($global:outputArray[$x].Write -eq ""){
                    $global:outputArray[$x].Write += $user
                }else{
                    $global:outputArray[$x].Write += ","+$user
                }
            }

            if($cFSR[$i] -like '*Modify*'){
                $y = [array]::indexof($global:outputArray, $userPath)
                if($global:outputArray[$y].Modify -eq ""){
                    $global:outputArray[$y].Modify += $user
                }else{
                    $global:outputArray[$y].Modify += ","+$user
                }
            }

            if($cFSR[$i] -like '*FullControl*'){
                if($global:outputArray[$x].FullControl -eq ""){
                    $global:outputArray[$x].FullControl += $user
                }else{
                    $global:outputArray[$x].FullControl += ","+$user
                }
            }

        }
    }
    $x += 1
    $cFSR = $null
    $addedUsers = $null
    $newPath = $currentFolder
}

$paramRights = Get-Acl $path | select AccessToString

$arrayParamRights = $paramRights -split '["\n\r"|"\r\n"|\n|\r]' 

$global:outputArray += [PSCustomObject]@{"Path" = "$path"; "Read" = ""; "Write" = ""; "Modify" =""; "FullControl" = ""}

foreach($right in $arrayParamRights){
    if($right -like '@{AccessToString=*'){
        $right = $right.Substring(17)
    }
    if($right -like '*}'){
        $right = $right.Substring(0, $right.Length-1)
    }

    if($right -like '*Read*'){
        if($global:outputArray[0].Read -eq ""){
            $global:outputArray[0].Read += $right.Substring(0, $right.IndexOf(" Allow"))
        }else{
            $global:outputArray[0].Read += ","+$right.Substring(0, $right.IndexOf(" Allow"))
        }

    }
    if($right -like '*Write*'){
        if($global:outputArray[0].Write -eq ""){
            $global:outputArray[0].Write += $right.Substring(0, $right.IndexOf(" Allow"))
        }else{
            $global:outputArray[0].Write += ", "+$right.Substring(0, $right.IndexOf(" Allow"))
        }
    }
    if($right -like '*FullControl*'){
        if($global:outputArray[0].FullControl -eq ""){
            $global:outputArray[0].FullControl += $right.Substring(0, $right.IndexOf(" Allow"))
        }else{
            $global:outputArray[0].FullControl += ", "+$right.Substring(0, $right.IndexOf(" Allow"))
        }
    }
}

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
    #checkForDifferences($newPath)

    $childFolders = ls $userPath -Directory -Recurse -Name

    # Foreach loop for going through all subfolders in the user input
    foreach($child in $childFolders){

        # Calling function to list differences between 
        checkForDifferences(Join-Path -Path $path -ChildPath $child)
    }
}

$global:outputArray| Out-GridView -Title "Results for $path"

Write-Host "`nWARNING`nIF YOU CLOSE THIS THE OUTPUT WILL DISAPPEAR!" -ForegroundColor Red
Read-Host -Prompt "`n`nPress Enter to exit"