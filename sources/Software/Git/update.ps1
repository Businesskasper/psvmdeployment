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

Write-Host "Update `"Git`"...   " -NoNewline

try {
    Remove-Item -Path "$($root)\*" -Exclude @("install.ps1", "update.ps1") -Recurse -Force -Confirm:$false
    
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    $latestRequest = Invoke-WebRequest -Method Get -Uri https://api.github.com/repos/git-for-windows/git/releases/latest -UseBasicParsing | ConvertFrom-Json
    $latestAsset = $latestRequest.assets | ? { $_.content_type -eq "application/executable" -and $_.name -like "*64-bit.exe" } | select -First 1
    
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    Invoke-WebRequest -Method Get -Uri $latestAsset.browser_download_url -UseBasicParsing -OutFile "$($root)\setup.exe"
    Write-Host $([char]0x221A) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}