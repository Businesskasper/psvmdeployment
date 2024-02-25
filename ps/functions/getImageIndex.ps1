function GetImageIndex([string]$imagePath, [string]$sku) {
    $filter = "*$($sku -replace " ", "*")*"
    $skuIndex = $null
    $index = 1;

    while ($null -eq $skuIndex)
    {
        try {
            $info = Get-WindowsImage -ImagePath $imagePath -Index $index
            if ($info.ImageName -like $filter) {
                $skuIndex = $info.ImageIndex
            }
            else {
                $index++
            }
        }
        catch {
            return $null
        }
    }

    return $skuIndex
}
