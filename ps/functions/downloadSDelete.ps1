function DownloadSDelete([string]$installDir) {
    $sdeletePath = [System.IO.Path]::combine($installDir, "sdelete64.exe")

    if (Test-Path -Path $sdeletePath) {
        return $sdeletePath
    }

    md $installDir -ea 0 | Out-Null
    $sdeleteZipPath = [System.IO.Path]::combine($installDir, "sdelete.zip")
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -method Get -uri "https://download.sysinternals.com/files/SDelete.zip" -outfile $sdeleteZipPath | Out-Null
    $ProgressPreference = "Continue"
       
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($sdeleteZipPath, $installDir)
    Remove-Item -Path $sdeleteZipPath -ErrorAction SilentlyContinue -Force

    if (-not (Test-Path -Path "HKCU:\Software\Sysinternals")) {
        New-Item -Path "HKCU:\Software\Sysinternals" | Out-Null
    }
    if (-not (Test-Path -Path "HKCU:\Software\Sysinternals\SDelete")) {
        New-Item -Path "HKCU:\Software\Sysinternals\" -Name Sdelete | Out-Null
    }
    New-ItemProperty -Path "HKCU:\Software\Sysinternals\SDelete" -Name EulaAccepted -Value 1 -ErrorAction SilentlyContinue | Out-Null

    return $sdeletePath
}