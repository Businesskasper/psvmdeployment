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

$install = Start-Process -FilePath ([System.IO.Path]::Combine($root, "setup.exe")) -ArgumentList @("/VERYSILENT") -Wait -PassThru

if ($install.ExitCode -ne 0) {
    Write-Error "$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)"
}

exit($install.ExitCode)