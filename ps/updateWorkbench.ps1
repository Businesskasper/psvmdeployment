if ($psISE) {
    $root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") {
        $root = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $root = $MyInvocation.MyCommand.Definition | Split-Path -Parent
    }
}

Get-ChildItem -Path ([System.IO.Path]::Combine($root, "..", "Sources", "Software")) `
    -Filter "update.ps1" `
    -Recurse -Depth 1 | % { . $_.FullName }
