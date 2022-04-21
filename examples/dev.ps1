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
            NodeName     = "Dev"
            Roles        = @($NodeRoles.VM)
            Applications = @($Applications.GoogleChrome, $Applications.VSCode, $Applications.NodeJSLatestStable, $Applications.Git)
            VhdxPath     = "$($global:root)\Sources\Images\en_windows_server_2019_updated_nov_2020_x64_dvd_8600b05f.vhdx"
            OSType       = 'Standard'
            RAM          = 8192MB
            DiskSize     = 120GB
            Cores        = 4
            Online       = $true
            Export       = $false
            JoinDomain   = $false
        }
    )
}