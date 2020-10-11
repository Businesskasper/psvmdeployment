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
            NodeName       = "SQLCore"
            Roles          = @($NodeRoles.VM, $NodeRoles.SQL)
            VhdxPath       = [io.path]::combine($global:root, "Sources", "Images", "en_windows_server_version_2004_updated_may_2020_x64_dvd_1e7f1cfa.vhdx")
            OSType         = 'Core'
            RAM            = 4096MB
            DiskSize       = 30GB
            Cores          = 4
            Online         = $true
            Export         = $false
        },
        @{
            NodeName       = "DC"
            Roles          = @($NodeRoles.DC, $NodeRoles.VM, $NodeRoles.SQL)
            VhdxPath       = [io.path]::combine($global:root, "Sources", "Images", "en_windows_server_2019_updated_may_2020_x64_dvd_5651846f.vhdx")
            OSType         = 'Standard'
            RAM            = 8192MB
            DiskSize       = 120GB
            Cores          = 4
            Online         = $false
            NICs           = @(
                @{
                    SwitchName = "Privat"
                    SwitchType = "Private"
                    IPAddress  = "192.168.1.10"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
            Export         = $false
        },
        @{
            NodeName       = "Dev"
            Roles          = @($NodeRoles.VM, $NodeRoles.SQL, $NodeRoles.DEV)
            VhdxPath       = [io.path]::combine($global:root, "Sources", "Images", "en_windows_server_2019_updated_may_2020_x64_dvd_5651846f.vhdx")
            OSType         = 'Standard'
            RAM            = 8192MB
            DiskSize       = 120GB
            Cores          = 4
            Online         = $false
            NICs           = @(
                @{
                    SwitchName = "Privat"
                    SwitchType = "Private"
                    IPAddress  = "192.168.1.10"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
            Export         = $false
            NodeVersion    = 'LatestStable'

        }
    )
}