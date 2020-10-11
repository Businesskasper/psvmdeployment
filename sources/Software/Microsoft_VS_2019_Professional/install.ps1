if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}


Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "certmgr.exe")) -ArgumentList @("-add", ([System.IO.Path]::Combine($scriptDir, "certificates", "manifestRootCertificate.cer")), "Microsoft Root Certificate Authority 2011", "-s", "-r", "LocalMachine", "root") -Wait
Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "certmgr.exe")) -ArgumentList @("-add", ([System.IO.Path]::Combine($scriptDir, "certificates", "manifestCounterSignRootCertificate.cer")), "Microsoft Root Certificate Authority 2010", "-s", "-r", "LocalMachine", "root") -Wait
Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "certmgr.exe")) -ArgumentList @("-add", ([System.IO.Path]::Combine($scriptDir, "certificates", "vs_installer_opc.RootCertificate.cer")), "Microsoft Root Certificate Authority", "-s", "-r", "LocalMachine", "root") -Wait



$install = Start-Process -FilePath ([System.IO.Path]::Combine($scriptDir, "vs_professional.exe")) -ArgumentList @(
    "--add Microsoft.VisualStudio.Workload.ManagedDesktop",
    "--add Microsoft.VisualStudio.Workload.NetWeb"
    "--add Component.GitHub.VisualStudio",
    "--includeOptional",
    #"--lang en-US", -> Exception "Unsupported Parameter "lang""
    "--passive",
    "--norestart",
    "--noWeb"
) -Wait -PassThru

if ($install.ExitCode -ne 0) {

    Write-Error "$($install.StartInfo.FileName) exited with Exit Code $($install.ExitCode)"
}