if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

Remove-Item -Path $scriptDir -Exclude @("update.ps1", "install.ps1", "certmgr.exe", "vs_Professional.exe") -Recurse -Force -Confirm:$false

$buildPackage = Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "vs_professional.exe")) -ArgumentList @(
    "--layout $($scriptDir)",
    "--add Microsoft.VisualStudio.Workload.ManagedDesktop",
    "--add Microsoft.VisualStudio.Workload.NetWeb"
    "--add Component.GitHub.VisualStudio",
    "--includeOptional",
    "--lang en-US",
    "--passive"
) -Wait -PassThru

if ($buildPackage.ExitCode -ne 0) {

    Write-Error "$($buildPackage.StartInfo.FileName) exited with Exit Code $($buildPackage.ExitCode)"
}