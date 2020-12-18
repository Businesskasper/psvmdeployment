if ($psISE) {

    $global:root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $global:root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

Get-ChildItem -Path ([System.IO.Path]::Combine($global:root, "..", "Sources", "Software")) -Recurse -Filter "update.ps1" -Depth 1 | % {

    . $_.FullName
}
