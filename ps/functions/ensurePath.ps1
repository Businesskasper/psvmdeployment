function EnsurePath([string]$path) {
    if ([String]::IsNullOrWhiteSpace($path)) {
        return
    }

    $parent = Split-Path -Path $path -Parent
    if ($null -ne $parent -and $parent -ne $path) {
        EnsurePath -path $parent
    }
   
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory | Out-Null
    }
}