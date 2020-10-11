if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}


$install = Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "setup.exe")) -ArgumentList @("/VERYSILENT", "/MERGETASKS=!runcode") -Wait -PassThru

if ($install.ExitCode -ne 0) {
            
    Write-Error "$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)"
}

md c:\users\default\.vscode\extensions -ea 0
md c:\users\public\.vscode\extensions -ea 0

foreach ($extension in (gci -Path ([System.IO.Path]::Combine($scriptDir, "Extensions")))) {
    
    Copy-Item -Path $extension.FullName -Destination "C:\users\Public\.vscode\extensions\" -Recurse -Force
    Copy-Item -Path $extension.FullName -Destination "C:\users\default\.vscode\extensions\" -Recurse -Force
}