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

Write-Host "Update `"SQL Server Management Studio`"...   " -NoNewLine

try {
    $setupPath = [System.IO.Path]::Combine($root, "SSMS-Setup-ENU.exe")
    
    Invoke-WebRequest -Method Get -Uri "https://aka.ms/ssmsfullsetup" -OutFile $setupPath

    Write-Host $([char]0x2713) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x274C) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}