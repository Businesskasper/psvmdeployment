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

Write-Host "Update `"Chrome`"...   " -NoNewLine

try {
    $ProgressPreference = "SilentlyContinue"
    Remove-Item -Path "$root\*" -Recurse -Force -Exclude @("AppAssociations.xml", "update.ps1") -Confirm:$false
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    $zipPath = [System.IO.Path]::Combine($root, "chrome.zip")
    $unzipPath = [System.IO.Path]::Combine($root, "chrome")
    
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    Invoke-WebRequest -Method Get -Uri "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B434CE955-AD3C-B4E8-6190-542FBB516D20%7D%26lang%3Den%26browser%3D4%26usagestats%3D1%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEB/dl/chrome/install/GoogleChromeEnterpriseBundle64.zip" -OutFile $zipPath
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $unzipPath)
    Remove-Item -Path $zipPath -Force -Confirm:$false
    
    Move-Item -Path ([System.IO.Path]::Combine($unzipPath, "Installers", "GoogleChromeStandaloneEnterprise64.msi")) -Destination $root -Force -Confirm:$false
    Remove-Item -Path $unzipPath -Force -Confirm:$false -Recurse

    Write-Host $([char]0x221A) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    $ProgressPreference = "Continue"
}