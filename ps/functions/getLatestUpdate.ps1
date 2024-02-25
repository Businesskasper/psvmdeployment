class Result {
    [string]$kb
    [string]$title
}

function GetLatestUpdate ([string]$Product, [string]$Version, [DateTime]$Month = [DateTime]::Now, [int]$RoundKey = 0) {
    if ($RoundKey -ge 4) {
        throw [Exception]::new("Keine Updates in den letzten vier Monaten gefunden")
    }

    $_month = $Month.ToString('yyyy-MM')

    $updateCatalog = Invoke-WebRequest -Uri "https://www.catalog.update.microsoft.com/Search.aspx?q=$($_month)%20$($Product)%20$($Version)"
    $table = $updateCatalog.ParsedHtml.getElementById('tableContainer').firstChild.firstChild

    foreach ($item in $table.childNodes) {
        $regex = [Regex]::new("$($_month) Cumulative Update for $($Product).*$($Version) for x64-based Systems \((KB\d+)\)")
        if ($Product -like "*Server*") {
            $regex = [Regex]::new("$($_month) Cumulative Update for (Microsoft server operating system|Windows Server)( $($Version)| version $($Version)|, version $($Version)) for x64-based Systems \((KB\d+)\)")
        }

        $m = $regex.Match($item.innerHTML) 
        if ($m.Success) {
            $res = [Result]@{
                kb = $m.Groups[3].Value
                title = $m.Value
            }
            return $res
        }
    }

    return GetLatestUpdate -Product $Product -Version $Version -Month ([DateTime]$Month).AddMonths(-1) -RoundKey ($RoundKey + 1)
}