if ($psISE) {

    $scriptDir = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $scriptDir = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}


Remove-Item -Path "$($scriptDir)\*" -Exclude @("install.ps1", "update.ps1") -Recurse -Force -Confirm:$false

$setupPath = [System.IO.Path]::Combine($scriptDir, "setup.exe")

$latestRequest = Invoke-WebRequest -Method Get -Uri https://api.github.com/repos/git-for-windows/git/releases/latest -UseBasicParsing | ConvertFrom-Json
$latestAsset = $latestRequest.assets | ? {$_.content_type -eq "application/executable" -and $_.name -like "*64-bit.exe"} | select -First 1

Invoke-WebRequest -Method Get -Uri $latestAsset.browser_download_url -UseBasicParsing -OutFile $setupPath