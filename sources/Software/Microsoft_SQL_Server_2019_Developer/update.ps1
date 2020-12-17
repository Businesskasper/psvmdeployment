if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

Remove-Item -Path $scriptDir\* -Recurse -Exclude "update.ps1" -Force

$isoPath = [System.IO.Path]::Combine($scriptDir, "SQLServer2019-x64-ENU-Dev.iso")

Invoke-WebRequest -Method Get -Uri "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-x64-ENU-Dev.iso" -OutFile $isoPath

$mountResult = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -PassThru
$mountVolume = $mountResult | Get-Volume
$mountDriveLetter = "$($mountVolume.DriveLetter):"

Copy-Item -Path "$mountDriveLetter\*" -Recurse -Destination $scriptDir -Force
Dismount-DiskImage -ImagePath $isoPath | Out-Null
Remove-Item -Path $isoPath -Force