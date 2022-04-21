if ($psISE) {
    $root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") { 
        $root = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
    }
}

Write-Host "Update `"SQL Server 2019 Developer Edition`"...   " -NoNewLine

try {
    $ProgressPreference = "SilentlyContinue"

    Remove-Item -Path $root\* -Recurse -Exclude "update.ps1" -Force
    
    $isoPath = [System.IO.Path]::Combine($root, "SQLServer2019-x64-ENU-Dev.iso")
    
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    Invoke-WebRequest -Method Get -Uri "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-x64-ENU-Dev.iso" -OutFile $isoPath
    
    $mountResult = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -PassThru
    $mountVolume = $mountResult | Get-Volume
    $mountDriveLetter = "$($mountVolume.DriveLetter):"
    
    Copy-Item -Path "$mountDriveLetter\*" -Recurse -Destination $root -Force
    Dismount-DiskImage -ImagePath $isoPath | Out-Null
    Remove-Item -Path $isoPath -Force

    Write-Host $([char]0x221A) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    $ProgressPreference = "Continue"
}