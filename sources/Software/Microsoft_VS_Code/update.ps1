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

Write-Host "Update `"Visual Studio Code`"...   "

try {
    $ProgressPreference = "SilentlyContinue"

    $setupPath = [System.IO.Path]::Combine($root, "setup.exe")
    
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    Invoke-WebRequest -Method Get -Uri "https://update.code.visualstudio.com/latest/win32-x64/stable" -OutFile $setupPath

    Write-Host $([char]0x221A) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    $ProgressPreference = "Continue"
}