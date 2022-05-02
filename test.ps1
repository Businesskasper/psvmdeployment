if ($psISE) {
    $global:root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") { 
        $global:root = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $global:root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
    }
}

# Load all classes, functions and role / application definitions
. $global:root\ps\classes.ps1
. $global:root\ps\functions.ps1
. $global:root\ps\roles.ps1

$a = [NodeConfiguration]@{
    NodeDefaults = [NodeDefaults]@{
        #LocalCredentials = [PSCustomObject]::new(".\Administrator", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
    }
    AllNodes = @(
        [Node]@{
            NodeName     = "Demo"
            Roles        = @($NodeRoles.VM, $NodeRoles.Dev)
            VhdxPath     = "$($global:root)\Sources\Images\en_windows_server_2019_updated_nov_2020_x64_dvd_8600b05f.vhdx"
            OSType       = 'Standard'
            RAM          = 8192MB
            DiskSize     = 60GB
            Cores        = 4
            <#
            NICs         = @(
                @{
                    SwitchName = "Extern LAN"
                    SwitchType = "External"
                    nic        = "Ethernet 3"
                    DHCP       = $true
                }
            )
            #>
        }
    )
}

$c = $a.ToConfigData()