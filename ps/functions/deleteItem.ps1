function DeleteItem([string]$path) {
    while (Test-Path -Path $path) {      
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
        }
        catch {
            if ($_.Exception.HResult -ne "-2147024864") {
                throw $_.Exception
            }
            Start-Sleep -Seconds 3
        }
    }      
}