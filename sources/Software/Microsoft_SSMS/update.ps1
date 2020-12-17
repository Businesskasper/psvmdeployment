if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

$setupPath = [System.IO.Path]::Combine($scriptDir, "SSMS-Setup-ENU.exe")

Invoke-WebRequest -Method Get -Uri "https://aka.ms/ssmsfullsetup" -OutFile $setupPath
