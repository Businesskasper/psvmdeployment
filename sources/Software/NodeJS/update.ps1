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

Write-Host "Update `"Node.js`"...   "

try {
    $ProgressPreference = "SilentlyContinue"

    Remove-Item -Path $root -Exclude @("update.ps1") -Recurse -Force -Confirm:$false
    
    #Get Versions
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    $versions = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing | ConvertFrom-Json
    $versions.ForEach({
        $_.version = [Version]::new($_.version.ToString().TrimStart("v"))
        $ve = $_.version
        $_ | Add-Member -MemberType NoteProperty -Name MajorVersion -Value $ve.Major
    }) 
    
    $versionsByMajor = $versions | ? {$_.lts -ne $false -and $_.files -contains "win-x64-msi"} | Sort-Object version -Descending | Group-Object MajorVersion 
    
    # Download latest stable
    $latestStable = $versionsByMajor[0].Group | select -First 1
    Write-Progress -Activity "Node.js" -Status "Latest Stable: $($latestStable.version)" -PercentComplete 0
    $downloadPath = New-Item -Path $root -Name LatestStable -ItemType Directory -Force
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v$($latestStable.version.ToString())/node-v$($latestStable.version.ToString())-x64.msi" -OutFile ([System.IO.Path]::Combine($downloadPath.FullName, "node-LatestStable-x64.msi")) -UseBasicParsing              
    
    # Download LTS versions per major release
    for ($i = 0; $i -lt $versionsByMajor.Count; $i++) {
        $lts = $versionsByMajor[$i].Group | select -First 1
        
        Write-Progress -Activity "Node.js" -Status $lts.version -PercentComplete (100 / $versionsByMajor.Count * $i)
       
        $downloadPath = New-Item -Path $root -Name $($lts.version.ToString().TrimStart("v")) -ItemType Directory -Force
        [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v$($lts.version.ToString())/node-v$($lts.version.ToString())-x64.msi" -OutFile ([System.IO.Path]::Combine($downloadPath.FullName, "node-v$($lts.version.ToString())-x64.msi")) -UseBasicParsing
    }

    Write-Progress -Activity "Node.js" -Completed

    Write-Host $([char]0x221A) -ForegroundColor Green 
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    $ProgressPreference = "Continue"
}