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
        <#@{
            NodeName       = "DC"
            Roles          = @($NodeRoles.DC, $NodeRoles.VM, $NodeRoles.SQL)
            VhdxPath       = [io.path]::combine($global:root, "Sources", "Images", "en_window_server_version_20h2_updated_nov_2020_x64_dvd_26fe579c.vhdx")
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
            NodeName       = "SQLCore"
            Roles          = @($NodeRoles.VM, $NodeRoles.SQL)
            VhdxPath       = [io.path]::combine($global:root, "Sources", "Images", "en_window_server_version_20h2_updated_nov_2020_x64_dvd_26fe579c.vhdx")
            OSType         = 'Core'
            RAM            = 4096MB
            DiskSize       = 30GB
            Cores          = 4
            Online         = $true
            Export         = $false
            NICs           = @(
                @{
                    SwitchName = "Privat"
                    SwitchType = "Private"
                    IPAddress  = "192.168.1.11"
                    SubnetCidr = "24"
                    DNSAddress = "192.168.1.10"
                    DHCP       = $false
                }
            )
            JoinDomain     = $true
        },
        #>
        @{
            NodeName       = "Dev"
            Roles          = @(
                                $NodeRoles.VM
                            )
            Applications   = @(
                                $Applications.GoogleChrome,
                                $Applications.VSPro2019, 
                                $Applications.VSCode, 
                                $Applications.NodeJSLatestStable,
                                $Applications.Git
                                $Applications.SSMS
                                $Applications.MSSQL2019DEV
                            )
            VhdxPath       = [io.path]::combine($global:root, "Sources", "Images", "en_windows_server_2019_updated_nov_2020_x64_dvd_8600b05f.vhdx")
            OSType         = 'Standard'
            RAM            = 8192MB
            DiskSize       = 120GB
            Cores          = 4
            Online         = $true
            Export         = $false
            JoinDomain     = $false
        }
    )
}