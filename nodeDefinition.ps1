return @{
    AllNodes = @(
        @{
            NodeName                    = "*"
            LocalCredentials            = [System.Management.Automation.PSCredential]::new(".\Administrator", (ConvertTo-SecureString "Passw0rd" -AsPlainText -Force))
            SystemLocale                = "de-DE"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            RebootNodeIfNeeded          = $true
        },
        @{
            NodeName     = "Demo"
            Roles        = @($NodeRoles.VM, $NodeRoles.SQL, $NodeRoles.DEV)
            VhdxPath     = "$($global:root)\Sources\Images\en_windows_server_2019_updated_nov_2020_x64_dvd_8600b05f.vhdx"
            OSType       = 'Standard'
            RAM          = 4096MB
            DiskSize     = 60GB
            Cores        = 2
            NICs         = @(
                @{
                    SwitchName = "Extern LAN"
                    SwitchType = "External"
                    nic        = "Ethernet 3"
                    DHCP       = $true
                }
            )
            Online       = $false
        }
    )
}