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