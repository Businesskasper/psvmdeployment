return [NodeConfiguration]@{
    NodeDefaults = [NodeDefaults]@{
        LocalCredentials = [PSCredential]::new(".\Administrator", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
        SystemLocale     = "de-DE"
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