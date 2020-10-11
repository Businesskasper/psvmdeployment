if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

$setupPath = [System.IO.Path]::Combine($scriptDir, "setup.exe")

Invoke-WebRequest -Method Get -Uri "https://update.code.visualstudio.com/latest/win32-x64/stable" -OutFile $setupPath
