if (-not [String]::IsNullOrWhitespace($PSScriptRoot)) {
    $scriptRoot = $PSScriptRoot
}
elseif ($psISE) {
    $scriptRoot = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") {
        $scriptRoot = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $scriptRoot = $MyInvocation.MyCommand.Definition | Split-Path -Parent
    }
}

Get-ChildItem -Path ([System.IO.Path]::Combine($scriptRoot, "..", "Sources", "Software")) `
    -Filter "update.ps1" `
    -Recurse -Depth 1 | % { . $_.FullName }
