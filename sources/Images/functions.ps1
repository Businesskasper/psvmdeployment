function GetLatestUpdate ([string]$Product, [string]$Version, [DateTime]$Month = [DateTime]::Now, [int]$RoundKey = 0) {
    if ($RoundKey -ge 4) {
        throw [Exception]::new("Keine Updates in den letzten vier Monaten gefunden")
    }

    $_month = $Month.ToString('yyyy-MM')

    $updateCatalog = Invoke-WebRequest -Uri "https://www.catalog.update.microsoft.com/Search.aspx?q=$($_month)%20$($Version)" 
    $table = $updateCatalog.ParsedHtml.getElementById('tableContainer').firstChild.firstChild

    foreach ($item in $table.childNodes) {
        if ($item.innerHTML -like "*$($_month) Cumulative Update for $($Product)*$($Version) for x64-based Systems (KB*") {
            $matches = [regex]::Matches($item.innerHTML, "KB(\d+)")
            return $matches[0].Value
        }
    }

    return GetLatestUpdate -Product $Product -Version $Version -Month ([DateTime]$Month).AddMonths(-1) -RoundKey ($RoundKey + 1)
}

function DownloadSDelete([string]$installDir) {
    $sdeletePath = [System.IO.Path]::combine($installDir, "sdelete64.exe")

    if (Test-Path -Path $sdeletePath) {
        return $sdeletePath
    }

    md $installDir -ea 0 | Out-Null
    $sdeleteZipPath = [System.IO.Path]::combine($installDir, "sdelete.zip")
    Invoke-WebRequest -method Get -uri "https://download.sysinternals.com/files/SDelete.zip" -outfile $sdeleteZipPath | Out-Null
        
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