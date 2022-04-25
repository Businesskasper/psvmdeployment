# Can be used to initially setup your machine.
# 1. EnablesHyper-V (if it's not already enabled)
# 2. Enables TLS 1.0 and 1.1 since they are required by PowerShellGet
# 3. Installs NuGet
# 4. Installs PowerShellGet
# 5. Registers PSGallery as default and trusted PowerShellGet Provider

if (-not [String]::IsNullOrWhitespace($PSScriptRoot)) {
    $scriptRoot = $PSScriptRoot
}
elseif ($psISE) {
    $scriptRoot = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") {
        $scriptRoot = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $scriptRoot = $MyInvocation.MyCommand.Definition | Split-Path -Parent
    }
}

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
        $ProgressPreference = "SilentlyContinue"
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
    finally {
        $ProgressPreference = "Continue"
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
$ProgressPreference = "SilentlyContinue"
$localProvider = Get-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | select -First 1
$remoteProvider = Find-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | select -First 1
$ProgressPreference = "Continue"
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
        $ProgressPreference = "SilentlyContinue"
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Write-Progress -Completed -Activity "*"
        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        Write-Host $([char]0x0078) -ForegroundColor Red
        Write-Host "Something went wrong:`n$($_.Exception.Message)"
        break
    }
    finally {
        $ProgressPreference = "Continue"
    }
}

Write-Host "Check if PowerShellGet is present and updated...   " -NoNewline
$updatePsGet = $false
$installPsGet = $false
$ProgressPreference = "SilentlyContinue"
$localPsGet = Get-Module -Name "PowerShellGet" -ListAvailable -ErrorAction SilentlyContinue -Refresh | select -First 1
$remotePsGet = Find-Module -Name "PowerShellGet" -ErrorAction SilentlyContinue | select -First 1
$ProgressPreference = "Continue"

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
        $ProgressPreference = "SilentlyContinue"
        Install-Module -Name PowerShellGet -SkipPublisherCheck -Force -ErrorAction Stop  | Out-Null
        Write-Progress -Activity "Installing package 'PowerShellGet'" -Completed
        Write-Progress -Activity "Installing package 'PackageManagement'" -Completed

        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        $installPsGetManually = $true
    }
    finally {
        $ProgressPreference = "Continue"
    }
}
elseif ($updatePsGet) {
    try {
        Write-Host "Update PowerShellGet...   " -NoNewline
        $ProgressPreference = "SilentlyContinue"
        Update-Module -Name PowerShellGet  -Force -ErrorAction Stop | Out-Null
        Write-Progress -Activity "Installing package 'PowerShellGet'" -Completed
        Write-Progress -Activity "Installing package 'PackageManagement'" -Completed

        Write-Host $([char]0x221A) -ForegroundColor Green
    }
    catch [Exception] {
        $installPsGetManually = $true
    }
    finally {
        $ProgressPreference = "Continue"
    }
}

if ($installPsGetManually) {
    $workingDir = "$($scriptRoot)\$([Guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Path $workingDir -ErrorAction SilentlyContinue | Out-Null
    try {
        Save-Module -Name PowerShellGet -Path $workingDir -Repository PSGallery
        $ProgressPreference = "SilentlyContinue"
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
        $ProgressPreference = "Continue"
        Remove-Item -Path $workingDir -Force -ErrorAction SilentlyContinue -Recurse | Out-Null
    }
}

Write-Host "Register PSGallery and set as trusted default provider...   " -NoNewline
try {
    [System.Net.WebClient]::new().Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $ProgressPreference = "SilentlyContinue"
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
finally {
    $ProgressPreference = "Continue"
}

if ($hyperVSetup.RestartNeeded) {
    Write-Host "Please Reboot" -ForegroundColor Yellow
}

Write-Host "Install shipped DSC modules...   " -NoNewline
try {
    $modules = Get-ChildItem -Path "$($scriptRoot)\modules" | ? {$_.Attributes -eq [System.IO.FileAttributes]::Directory }
    $modules | % { Copy-Item -Path $_.FullName -Container -Destination "$($env:ProgramFiles)\WindowsPowerShell\Modules" -Force -Recurse | Out-Null}

    Write-Host $([char]0x221A) -ForegroundColor Green
}
catch [Exception] {
    Write-Host $([char]0x0078)
    Write-Host "Something went wrong:`n$($_.Exception.Message)"
    break
}