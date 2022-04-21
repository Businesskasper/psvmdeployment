return @{
    AllNodes = @(
        @{
            NodeName                    = "*"
            LocalCredentials            = [System.Management.Automation.PSCredential]::new(".\Administrator", (ConvertTo-SecureString "Passw0rd" -AsPlainText -Force))
            DomainCredentials           = [System.Management.Automation.PSCredential]::new("LTW\Administrator", (ConvertTo-SecureString "Passw0rd" -AsPlainText -Force))
            DomainName                  = "ltw.local"
            DomainNetBios               = "LTW"
            SystemLocale                = "de-DE"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            RebootNodeIfNeeded          = $true
        },
        @{
            NodeName = "DC"
            Roles    = @($NodeRoles.VM, $NodeRoles.DC, $NodeRoles.SQL)
            VhdxPath = "$($global:root)\Sources\Images\en_window_server_version_20h2_updated_nov_2020_x64_dvd_26fe579c.vhdx"
            OSType   = 'Standard'
            RAM      = 2048MB
            DiskSize = 20GB
            Cores    = 2
            Online   = $false
            NICs     = @(
                @{
                    SwitchName = "ltw-local"
                    SwitchType = "Private"
                    IPAddress  = "192.168.1.10"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
            Export   = $false
        },
        @{
            NodeName   = "SQLCore"
            Roles      = @($NodeRoles.VM, $NodeRoles.SQL)
            VhdxPath   = "$($global:root)\Sources\Images\en_window_server_version_20h2_updated_nov_2020_x64_dvd_26fe579c.vhdx"
            OSType     = 'Core'
            RAM        = 4096MB
            DiskSize   = 40GB
            Cores      = 4
            Export     = $false
            NICs       = @(
                @{
                    SwitchName = "ltw-local"
                    SwitchType = "Private"
                    IPAddress  = "192.168.1.11"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
            Online     = $true
            JoinDomain = $true
        }
    )
}