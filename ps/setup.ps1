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

Write-Host "Try to import Hyper-V module...   " -NoNewLine
$hvModule = Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue
if ($null -eq $hvModule) {
    Write-Host $([char]0x274C)
    $installHyperV = $true

}
else {
    Write-Host $([char]0x2713) -ForegroundColor Green
    Write-Host "Check if Hyper-V is installed...   " -NoNewLine
    $vmHost = Get-VMHost -ErrorAction SilentlyContinue
    if ($null -eq $vmHost) {
        Write-Host $([char]0x274C)
        $installHyperV = $true
    }
    else {
        Write-Host $([char]0x2713) -ForegroundColor Green
        $installHyperV = $false
    }
}

if ($installHyperV) {
    Write-Host "Install Hyper-V...   " -NoNewline
    try {
        $hyperVSetup = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction Stop | Out-Null
        Write-Host $([char]0x2713) -ForegroundColor Green
        if ($hyperVSetup.RestartNeeded) {
            Write-Host "Please Reboot after completion" -ForegroundColor Yellow
        }
    }
    catch [Exception] {
        Write-Host $([char]0x274C)
        Write-Host "Something went wrong:`n$($_.Exception.Message)"
        break
    }
}

Write-Host "Enable required TLS Versions for PowerShellGet...   " -NoNewline
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Write-Host $([char]0x2713) -ForegroundColor Green
}
catch [Exception] {
    Write-Host $([char]0x274C)
    Write-Host "Something went wrong:`n$($_.Exception.Message)"
    break 
}

Write-Host "Install NuGet...   " -NoNewline
try {
    Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
    Write-Host $([char]0x2713) -ForegroundColor Green
}
catch [Exception] {
    Write-Host $([char]0x274C)
    Write-Host "Something went wrong:`n$($_.Exception.Message)"
    break 
}

Write-Host "Install PowerShellGet...   " -NoNewline
try {
    Install-Module -Name PowerShellGet -Force -ErrorAction Stop | Out-Null
    Update-Module -Name PowerShellGet -Force -ErrorAction Stop | Out-Null
    Write-Host $([char]0x2713) -ForegroundColor Green
}
catch [Exception] {
    if ($_.Exception.Message -notlike "*Find-Package,Install-Package*") {
        Write-Host $([char]0x274C)
        Write-Host "Something went wrong:`n$($_.Exception.Message)"
        break 
    }
    else {
        # Old Version is installed, delete and install manually
        $workingDir = "$($root)\$([Guid]::NewGuid().Guid)"
        New-Item -ItemType Directory -Path $workingDir -ErrorAction SilentlyContinue | Out-Null
        try {
            Save-Module -Name PowerShellGet -Path $workingDir -Repository PSGallery
            'PowerShellGet', 'PackageManagement' | % {
                $targetDir = "$($env:ProgramFiles)\WindowsPowerShell\Modules\$($_)"
                Remove-Item "$($targetDir)\*" -Recurse -Force | Out-Null
                Copy-Item "$($workingDir)\$($_)\*\*" "$($targetDir)\" -Recurse -Force | Out-Null
            }
            Write-Host $([char]0x2713) -ForegroundColor Green
        }
        catch [Exception] {
            Write-Host $([char]0x274C)
            Write-Host "Something went wrong:`n$($_.Exception.Message)"
            break 
        }
        finally {
            Remove-Item -Path $workingDir -Force -ErrorAction SilentlyContinue -Recurse | Out-Null
        }
    }
}

Write-Host "Register PSGallery and set as trusted default provider...   " -NoNewline
try {
    [System.Net.WebClient]::new().Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $psGalleryProvider = Get-PSRepository | ? {$_.SourceLocation -eq "https://www.powershellgallery.com/api/v2" } | select -first 1
    if ($null -eq $psGalleryProvider) {
        Register-PSRepository -Default -InstallationPolicy Trusted
    }
    elseif ($psGalleryProvider.InstallationPolicy -ne "Trusted") {
        Set-PSRepository -Name $psGalleryProvider.Name -InstallationPolicy "Trusted"
    }
    Write-Host $([char]0x2713) -ForegroundColor Green
}
catch [Exception] {
    Write-Host $([char]0x274C)
    Write-Host "Something went wrong:`n$($_.Exception.Message)"
    break 
}

if ($hyperVSetup.RestartNeeded) {
    Write-Host "Please Reboot" -ForegroundColor Yellow
}

