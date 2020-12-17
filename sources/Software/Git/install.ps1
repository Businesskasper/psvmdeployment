if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}


$install = Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "setup.exe")) -ArgumentList @("/VERYSILENT") -Wait -PassThru

if ($install.ExitCode -ne 0) {
            
    Write-Error "$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)"
}


exit($install.ExitCode)