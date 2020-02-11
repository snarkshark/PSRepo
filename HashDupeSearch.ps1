#Hardcoded params are bad, I know
$global:CurrentHashtable = @{}
$global:CurrentResulttable = @{}
$pageSize = 1000
$global:currentPage = 1
$global:hashLocation = "C:\temp\hashes\"
 
#region Build Index functions
    #Step Functions
    function GetAllHashesAtLocation(){
        param(
            $CurrentFolder
        )
    
        $files = dir $currentFolder | where-object {-not ($_.mode -like "d*")}
        PutHashesInTable ($files | %{$hash = get-filehash $_.fullname; return $hash} )
        $folders = dir $currentFolder | where-object {($_.mode -like "d*")}

        foreach($folder in $folders){
            GetAllHashesAtLocation $folder.fullname
        }
    }
    function PutHashesInTable(){
        param(
            $fileHashes
        )
        foreach ($hash in $fileHashes){
            if([bool]($CurrentHashtable[$hash.hash])){
                $global:CurrentHashtable[$hash.hash].add($hash)
            }
            else{
                $global:CurrentHashtable.add($hash.hash, [System.Collections.ArrayList]@($hash))
            }
            if(($global:CurrentHashtable.values|%{$start += $_.count} -Begin {$start = 0} -end {$start}) -gt $pageSize){
                SaveHashesAndFlush
            }
        }
    }
    function SaveHashesAndFlush(){
		write-host ("Writing page to "+$global:hashLocation + "Hashtable-"+ $global:currentPage+".json" )
        ($global:CurrentHashtable | convertto-json) | out-file ($global:hashLocation + "Hashtable-"+ $global:currentPage+".json")
        $global:currentPage++        
        $global:CurrentHashtable = @{}
    }
    #Primary flow
    function BuildHashIndex(){
        param(
            $rootDir = $env:USERPROFILE
        )
        GetAllHashesAtLocation $rootDir
        SaveHashesAndFlush
    }
#endregion

#region Index Query and Delete
    function QueryDuplicateFromFiles(){
        param(
            $QueryHash
        )
        foreach($file in (dir $global:hashLocation)){
            $FileCat = cat $file.fullname
            if($filecat -like ("*"+$QueryHash+"*")){
                $FileContentObject = ($FileCat| ConvertFrom-Json )
                ($FileContentObject.psobject.properties | select-object *) | %{
                    if($_.name -eq $QueryHash){
                        if($global:CurrentResulttable[$file.fullname]){
                            $global:CurrentResulttable[$file.fullname].add($_.value)
                        }
                        else{
                            $global:CurrentResulttable[$file.fullname] = [System.Collections.ArrayList]@($_.value)
                        }
                    }
                }
            }
        }
    }
    function RemoveDuplicateFromFile(){
        param(
            $duplicateHashObj, $filePath
        )
        $FileContentObject = (cat $filePath| ConvertFrom-Json )
        $newFile = @{}
        ($FileContentObject.psobject.properties | select-object *) | %{
            $add = $true
            foreach($entry in $_.value){
                if($entry.path -eq $duplicateHashObj.path){
                    $add = $false
                }
            }
            if($add){
                if($newFile[$_.name]){
                    $newFile[$_.name].add($_.value)
                }
                else{
                    $newFile[$_.name] = [System.Collections.ArrayList]@($_.value)
                }
            }
        }
        $newfile | convertto-json | Out-File $filePath
    }
#endregion

#region Console Menu
function drawScreen(){

}
function MenuLoop(){
    
}
#endregion
