return [NodeConfiguration]@{
    NodeDefaults = [NodeDefaults]@{
        LocalCredentials  = [PSCredential]::new(".\Administrator", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
        SystemLocale      = "de-DE"
        DomainCredentials = [PSCredential]::new("LTW\Administrator", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
        DomainName        = "ltw.local"
        DomainNetBios     = "LTW"
    }
    AllNodes = @(
        [Node]@{
            NodeName = "DC"
            Roles    = @($NodeRoles.VM, $NodeRoles.DC)
            VhdxPath = "$($global:root)\Sources\Images\en_window_server_version_20h2_updated_nov_2020_x64_dvd_26fe579c.vhdx"
            OSType   = 'Standard'
            RAM      = 2048MB
            DiskSize = 20GB
            Cores    = 2
            NICs     = @(
                [PrivateNic]@{
                    SwitchName = "ltw-local"
                    IPAddress  = "192.168.1.10"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
        },
        [Node]@{
            NodeName   = "SQLCore"
            Roles      = @($NodeRoles.VM, $NodeRoles.SQL)
            VhdxPath   = "$($global:root)\Sources\Images\en_window_server_version_20h2_updated_nov_2020_x64_dvd_26fe579c.vhdx"
            OSType     = 'Core'
            RAM        = 4096MB
            DiskSize   = 40GB
            Cores      = 4
            JoinDomain = $true
            NICs       = @(
                [PrivateNic]@{
                    SwitchName = "ltw-local"
                    IPAddress  = "192.168.1.11"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
        }
    )
}