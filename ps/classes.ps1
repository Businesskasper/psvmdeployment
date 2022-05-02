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


. "$($scriptRoot)\classes\binary.ps1"
. "$($scriptRoot)\classes\application.ps1"
. "$($scriptRoot)\classes\psModule.ps1"
. "$($scriptRoot)\classes\nodeRole.ps1"
. "$($scriptRoot)\classes\nic.ps1"
. "$($scriptRoot)\classes\node.ps1"


<#

$a = [NodeConfiguration]@{
    NodeDefaults = [NodeDefaults]@{
        #LocalCredentials = [PSCustomObject]::new(".\Administrator", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
    }
    AllNodes = @(
        [Node]@{
            NodeName     = "Demo"
            VhdxPath     = "$($global:root)\Sources\Images\en_windows_server_2019_updated_nov_2020_x64_dvd_8600b05f.vhdx"
            OSType       = 'Standard'
            RAM          = 8192MB
            DiskSize     = 60GB
            Cores        = 4
            
            NICs         = @(
                [ExternalNic]@{
                    SwitchName = "Extern LAN"
                    Nic        = "Ethernet 3"
                    DHCP       = $true
                }
            )
            
        }
    )
}

$c = $a.ToConfigData()

#>