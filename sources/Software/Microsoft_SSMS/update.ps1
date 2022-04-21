﻿if ($psISE) {
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

$setupPath = [System.IO.Path]::Combine($root, "SSMS-Setup-ENU.exe")

Invoke-WebRequest -Method Get -Uri "https://aka.ms/ssmsfullsetup" -OutFile $setupPath
