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

Write-Host "Update `"Visual Studio 2019 Professional`"...   " -NoNewline

try {
    Remove-Item -Path $root -Exclude @("update.ps1", "install.ps1", "certmgr.exe") -Recurse -Force -Confirm:$false
    
    $setupFile = [System.IO.Path]::Combine($root, "vs_professional.exe")
    Invoke-WebRequest -Method Get -Uri "https://aka.ms/vs/16/release/vs_professional.exe" -OutFile $setupFile
    
    $buildPackage = Start-Process -FilePath ([System.IO.Path]::Combine($root, "vs_professional.exe")) -ArgumentList @(
        "--layout $($root)",
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

    Write-Host $([char]0x221A) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}