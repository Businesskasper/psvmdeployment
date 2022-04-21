function SetItemProperty([string]$path, [string]$name, [string]$type, [object]$value) {
    EnsurePath -path $path

    $key = Get-Item -Path $path
    if ($null -eq $key) {
        New-Item -Path $path | Out-Null
    }

    $property = Get-ItemProperty -Path $path -Name $name
    if ($null -eq $property) {
        New-ItemProperty -Path $path -Name $name -PropertyType $type -Value $value | Out-Null
    }
    else {
        Set-ItemProperty -Path $path -Name $name -Value $value
    }
}