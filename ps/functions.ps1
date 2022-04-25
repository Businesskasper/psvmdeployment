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

. "$($root)\functions\deleteItem.ps1"
. "$($root)\functions\ensurePath.ps1"
. "$($root)\functions\setItemProperty.ps1"
. "$($root)\functions\deployVM.ps1"
. "$($root)\functions\ensureVMNic.ps1"
. "$($root)\functions\showVMLog.ps1"
. "$($root)\functions\getNicTask.ps1"
. "$($root)\functions\getLatestUpdate.ps1"
. "$($root)\functions\downloadSDelete.ps1"