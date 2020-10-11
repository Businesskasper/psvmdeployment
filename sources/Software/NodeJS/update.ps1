﻿if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

Remove-Item -Path $scriptDir -Exclude @("update.ps1") -Recurse -Force -Confirm:$false



#Get Versions
$versions = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing | ConvertFrom-Json
$versions.ForEach({

    $_.version = [Version]::new($_.version.ToString().TrimStart("v"))
    $ve = $_.version
    $_ | Add-Member -MemberType NoteProperty -Name MajorVersion -Value $ve.Major
}) 


$versions | ? {$_.lts -ne $false -and $_.files -contains "win-x64-msi"} | Sort-Object version -Descending | Group-Object MajorVersion | % {

    $lts = $_.Group | select -First 1

    Write-Host "Download $($lts.version)"

    $downloadPath = New-Item -Path $scriptDir -Name $($lts.version.ToString().TrimStart("v")) -ItemType Directory -Force
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v$($lts.version.ToString())/node-v$($lts.version.ToString())-x64.msi" -OutFile ([System.IO.Path]::Combine($downloadPath.FullName, "node-v$($lts.version.ToString())-x64.msi")) -UseBasicParsing
}

                