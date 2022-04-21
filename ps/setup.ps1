# Can be used to initially setup your machine.
# 1. EnablesHyper-V (if it's not already enabled)
# 2. Enables TLS 1.0 and 1.1 since they are required by PowerShellGet
# 3. Installs NuGet
# 4. Installs PowerShellGet
# 5. Registers PSGallery as default and trusted PowerShellGet Provider

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

Write-Host ([Environment]::NewLine)

Write-Host "Check if Hyper-V service and module are installed...   " -NoNewLine
$installHyperV = $false
$hvModule = Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue
if ($null -eq $hvModule) {
    Write-Host $([char]0x0078) -ForegroundColor Red
    $installHyperV = $true
}
else {
    $vmHost = Get-VMHost -ErrorAction SilentlyContinue
    if ($null -eq $vmHost) {
        Write-Host $([char]0x0078) -ForegroundColor Red
        $installHyperV = $true
    }
    else {
        Write-Host $([char]0x221A) -ForegroundColor Green
        $installHyperV = $false
    }
}

if ($installHyperV) {
    Write-Host "Install Hyper-V...   " -NoNewline
    try {
        $hyperVSetup = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction Stop | Out-Null
        Write-Progress -Completed -Activity "*"
        Write-Host $([char]0x221A) -ForegroundColor Green
        if ($hyperVSetup.RestartNeeded) {
            Write-Host "Please Reboot after completion" -ForegroundColor Yellow
        }
    }
    catch [Exception] {
        Write-Host $([char]0x0078) -ForegroundColor Red
        Write-Host "Something went wrong:`n$($_.Exception.Message)"
        break
    }
}

Write-Host "Enable required TLS Versions for PowerShellGet...   " -NoNewline
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Write-Host $([char]0x221A) -ForegroundColor Green
}
catch [Exception] {
    Write-Host $([char]0x0078) -ForegroundColor Red
    Write-Host "Something went wrong:`n$($_.Exception.Message)"
    break
}

Write-Host "Check if the default Package Provider is present and updated...   " -NoNewline
$installPackageProvider = $false
$localProvider = Get-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | select -First 1
$remoteProvider = Find-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | select -First 1
if ($localProvider -eq $null -or $remoteProvider.Version -gt $localProvider.Version) {
    $installPackageProvider = $true
    Write-Host $([char]0x0078) -ForegroundColor Red
}
else {
    Write-Host $([char]0x221A) -ForegroundColor Green
}

if ($installPackageProvider) {
    Write-Host "Install the default Package Provider...   " -NoNewline
    try {
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Write-Progress -Completed -Activity "*"
        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        Write-Host $([char]0x0078) -ForegroundColor Red
        Write-Host "Something went wrong:`n$($_.Exception.Message)"
        break
    }
}

Write-Host "Check if PowerShellGet is present and updated...   " -NoNewline
$updatePsGet = $false
$installPsGet = $false
$localPsGet = Get-Module -Name "PowerShellGet" -ListAvailable -ErrorAction SilentlyContinue -Refresh | select -First 1
$remotePsGet = Find-Module -Name "PowerShellGet" -ErrorAction SilentlyContinue | select -First 1

if ($null -eq $localPsGet) {
    $installPsGet = $true
    Write-Host $([char]0x0078) -ForegroundColor Red
}
elseif ($remotePsGet.Version -gt $localPsGet.Version) {
    $updatePsGet = $true
    Write-Host $([char]0x0078) -ForegroundColor Red
}
else {
    Write-Host $([char]0x221A) -ForegroundColor Green
}

if ($installPsGet) {
    try {
        Write-Host "Install PowerShellGet...   " -NoNewline
        Install-Module -Name PowerShellGet -SkipPublisherCheck -Force -ErrorAction Stop  | Out-Null
        Write-Progress -Activity "Installing package 'PowerShellGet'" -Completed
        Write-Progress -Activity "Installing package 'PackageManagement'" -Completed

        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        $installPsGetManually = $true
    }
}
elseif ($updatePsGet) {
    try {
        Write-Host "Update PowerShellGet...   " -NoNewline
        Update-Module -Name PowerShellGet  -Force -ErrorAction Stop | Out-Null
        Write-Progress -Activity "Installing package 'PowerShellGet'" -Completed
        Write-Progress -Activity "Installing package 'PackageManagement'" -Completed

        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        $installPsGetManually = $true
    }
}

if ($installPsGetManually) {
    $workingDir = "$($root)\$([Guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Path $workingDir -ErrorAction SilentlyContinue | Out-Null
    try {
        Save-Module -Name PowerShellGet -Path $workingDir -Repository PSGallery
        Write-Progress -Activity "Installing package 'PowerShellGet'" -Completed
        Write-Progress -Activity "Installing package 'PackageManagement'" -Completed

        'PowerShellGet', 'PackageManagement' | % {
            $targetDir = "$($env:ProgramFiles)\WindowsPowerShell\Modules\$($_)"
            Remove-Item "$($targetDir)\*" -Recurse -Force | Out-Null
            Copy-Item "$($workingDir)\$($_)\*\*" "$($targetDir)\" -Recurse -Force | Out-Null
        }
        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        Write-Host $([char]0x0078) -ForegroundColor Red
        Write-Host "Something went wrong:`n$($_.Exception.Message)"
        break
    }
    finally {
        Remove-Item -Path $workingDir -Force -ErrorAction SilentlyContinue -Recurse | Out-Null
    }
}

Write-Host "Register PSGallery and set as trusted default provider...   " -NoNewline
try {
    [System.Net.WebClient]::new().Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $psGalleryProvider = Get-PSRepository | ? {$_.SourceLocation -eq "https://www.powershellgallery.com/api/v2" } | select -first 1
    if ($null -eq $psGalleryProvider) {
        Register-PSRepository -Default -InstallationPolicy Trusted
        Write-Progress -Completed -Activity "*"
    }
    elseif ($psGalleryProvider.InstallationPolicy -ne "Trusted") {
        Set-PSRepository -Name $psGalleryProvider.Name -InstallationPolicy "Trusted"
        Write-Progress -Completed -Activity "*"
    }
    Write-Host $([char]0x221A) -ForegroundColor Green
}
catch [Exception] {
    Write-Host $([char]0x0078)
    Write-Host "Something went wrong:`n$($_.Exception.Message)"
    break
}

if ($hyperVSetup.RestartNeeded) {
    Write-Host "Please Reboot" -ForegroundColor Yellow
}
