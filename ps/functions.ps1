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

. "$($scriptRoot)\functions\deleteItem.ps1"
. "$($scriptRoot)\functions\ensurePath.ps1"
. "$($scriptRoot)\functions\setItemProperty.ps1"
. "$($scriptRoot)\functions\deployVM.ps1"
. "$($scriptRoot)\functions\ensureVMNic.ps1"
. "$($scriptRoot)\functions\showVMLog.ps1"
. "$($scriptRoot)\functions\getNicTask.ps1"
. "$($scriptRoot)\functions\getLatestUpdate.ps1"
. "$($scriptRoot)\functions\downloadSDelete.ps1"
. "$($scriptRoot)\functions\getImageIndex.ps1"