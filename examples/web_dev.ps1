return [NodeConfiguration]@{
    NodeDefaults = [NodeDefaults]@{
        LocalCredentials = [PSCredential]::new(".\Administrator", (ConvertTo-SecureString -AsPlainText -Force -String "Passw0rd"))
        SystemLocale     = "de-DE"
    }
    AllNodes = @(
        [Node]@{
            NodeName     = "Demo"
            Roles        = @($NodeRoles.VM)
            Applications = @($Applications.GoogleChrome, $Applications.VSCode, $Applications.NodeJSLatestStable, $Applications.Git)
            VhdxPath     = "$($global:root)\Sources\Images\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.vhdx"
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