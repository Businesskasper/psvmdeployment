Configuration VMPlaybook {

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 6.3.0.0
    Import-DscResource -ModuleName xNetworking -ModuleVersion 5.5.0.0
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 11.0.0.0
    Import-DSCResource -ModuleName xWebAdministration -ModuleVersion 2.3.0.0
    Import-DscResource -ModuleName xInstallExe -ModuleVersion 1.2
    Import-DscResource -ModuleName xRemoteDesktopAdmin -ModuleVersion 1.1.0.0
    Import-DscResource -ModuleName xWinEventLog -ModuleVersion 1.2.0.0
    Import-DscResource -ModuleName xDSCHelper -ModuleVersion 1.0
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.22.0.0
    Import-DscResource -ModuleName xNodeJS -ModuleVersion 1.0


    # Settings for all nodes
    Node $AllNodes.NodeName {
        
        # Enable DSC analytic log
        xWinEventLog DSCAnalyticLog {
            LogName   = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled = $true
            LogMode   = 'Retain'
        }

        # Network configuration
        foreach ($nic in $node.NICS | ? { $_.IPAddress }) {
            xVmNetConfig $nic.SwitchName {
                NicName      = $nic.SwitchName
                IPAddress    = $nic.IPAddress
                PrefixLength = $nic.SubnetCidr
                DNSAddress   = $nic.DNSAddress
            }
        }

        if ($node.Online) {
            xVmNetConfig Online {
                NicName = 'Online'
                DHCP    = $true
            }
        }
   
        # Disable firewall
        xFirewallProfile Private {
            Name    = 'Private'
            Enabled = 'False'
        }

        xFirewallProfile Public {
            Name    = 'Public'
            Enabled = 'False'
        }
        
        xFirewallProfile Domain {
            Name    = 'Domain'
            Enabled = 'False'
        }
        
        if ($node.DomainName -and $node.Roles -notcontains $NodeRoles.DC -and $node.JoinDomain) {

            # Wait for the domain to become ready to join
            xWaitForADDomain WaitForDomain {
                DomainName       = $node.DomainName
                RetryIntervalSec = 60
                RetryCount       = 25
            }

            Computer JoinDomain {
                Name       = $node.NodeName
                DomainName = $node.DomainName
                Credential = $node.DomainJoinCredentials
                DependsOn  = '[xWaitForADDomain]WaitForDomain'
            }   
        }
        
        foreach ($localAdmin in $node.LocalAdmins) {
            Group LocalAdmins {
                GroupName        = "Administrators"
                MembersToInclude = $localAdmin
            }
        }     
    }   
    
    # Settings for all nodes with role DC
    Node $AllNodes.Where( { $_.Roles -contains $NodeRoles.DC } ).NodeName {

        #Rollen DNS, DHCP und ADDS installieren
        WindowsFeature DNS {
            Ensure = 'Present'
            Name   = 'DNS'
        }

        if ($node.OSType -eq 'Standard') {
            WindowsFeature DNSRsat {
                Ensure    = 'Present'
                Name      = 'RSAT-DNS-Server'
                DependsOn = '[WindowsFeature]DNS'
            }
        }
        
        if ($node.DHCPScopeStart) {
            WindowsFeature DHCP {
                Ensure = 'Present'
                Name   = 'DHCP'
            }

            WindowsFeature DHCPRsat {
                Ensure    = 'Present'
                Name      = 'RSAT-DHCP'
                DependsOn = '[WindowsFeature]DHCP'
            }
        }
        
        WindowsFeature ADDS {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
            DependsOn            = @('[WindowsFeature]DNS')
        }

        if ($node.OSType -eq 'Standard') {
            WindowsFeature ADDSRsat {
                Ensure    = 'Present'
                Name      = 'RSAT-ADDS'
                DependsOn = '[WindowsFeature]ADDS'
            }
        }

        #DC Promo
        xADDomain DC {
            DomainName                    = $node.DomainName
            DomainNetbiosName             = $node.DomainNetBios
            DomainAdministratorCredential = $node.LocalCredentials
            SafemodeAdministratorPassword = $node.LocalCredentials
        }  
        
        Script RebootDomain {
            TestScript = {
                return (Test-Path HKLM:\SOFTWARE\DSC\RebootDomain)
            }
            SetScript  = {
                New-Item -Path HKLM:\SOFTWARE\DSC\RebootDomain -Force
                $global:DSCMachineStatus = 1 
            }
            GetScript  = { 
                return @{
                    Result = $(Test-Path "HKLM:\SOFTWARE\DSC\RebootDomain")
                }
            }
        }
    }
    
    # Settings for all nodes with role "SQL"
    Node $AllNodes.Where({ $_.Roles -contains $NodeRoles.SQL }).NodeName {

        SqlSetup SQL2019 {
            Action              = 'Install'
            SourcePath          = 'C:\Sources\SQL\Microsoft_SQL_Server_2019_Developer'
            Features            = 'SQLEngine'
            SQLCollation        = 'Latin1_General_100_CS_AS'
            InstanceName        = "SQL2019"
            SuppressReboot      = $false
            UpdateEnabled       = $false
            SQLSysAdminAccounts = @($node.LocalCredentials.UserName, $node.DomainCredentials.UserName) | ? { -not ([String]::IsNullOrWhiteSpace($_)) }
            InstallSharedDir    = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir         = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir   = 'C:\SQL\Data'
            SQLUserDBDir        = 'C:\SQL\Data'
            SQLUserDBLogDir     = 'C:\SQL\Data'
            SQLTempDBDir        = 'C:\SQL\Data'
            SQLTempDBLogDir     = 'C:\SQL\Data'
            SQLBackupDir        = 'C:\SQL\Backup'
            SQLSvcAccount       = if ($node.DomainCredentials -ne $null -and ($node.JoinDomain -or $node.Roles.contains($NodeRoles.DC))) { $node.DomainCredentials } else { $node.LocalCredentials }
        }

        ServiceSet SQLService {
            Ensure      = 'Present'
            Name        = 'MSSQL`$SQL2019'
            StartupType = 'Automatic'
            State       = 'Running'
            DependsOn   = '[SqlSetup]SQL2019'
        }

        if ($node.OSType -eq "Standard") {
            xInstallExe Microsoft_SSMS {
                Ensure     = 'Present'
                BinaryPath = 'C:\Sources\Software\Microsoft_SSMS\SSMS-Setup-ENU.exe'
                Arguments  = '/s'
                AppName    = 'SQL Server Management Studio 18.0'
                ExitCodes  = @(0)
                TestPath   = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{673f06b0-3fd3-4b11-a775-3359fa5df604}'
                Shortcut   = @{
                    Exe = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
                }
            }
        }

        Script RebootSQL {
            TestScript = {
                return (Test-Path HKLM:\SOFTWARE\DSC\RebootSQL)
            }
            SetScript  = {
                New-Item -Path HKLM:\SOFTWARE\DSC\RebootSQL -Force
                $global:DSCMachineStatus = 1 
            }
            GetScript  = { 
                return @{
                    Result = $(Test-Path "HKLM:\SOFTWARE\DSC\RebootSQL")
                }
            }
        }
    } 

    # Settings for all nodes with role "DEV"
    Node $AllNodes.Where({ $_.Roles -contains $NodeRoles.DEV -and $_.OSType -eq "Standard" }).NodeName {
    
        xInstallExe VS_2019_Professional {
            Ensure     = 'Present'
            BinaryPath = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            Arguments  = 'C:\Sources\Software\Microsoft_VS_2019_Professional\install.ps1'
            AppName    = 'Visual Studio 2019 Professional'
            ExitCodes  = @(0, 3010)
            TestPath   = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\83d3efc7'
            Shortcut   = @{
                Exe = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe"
            }
        }

        xInstallExe VSCode {
            Ensure     = 'Present'
            BinaryPath = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            Arguments  = 'C:\Sources\Software\Microsoft_VS_Code\install.ps1'
            AppName    = 'Visual Studio Code'
            ExitCodes  = @(0, 3010)
            TestPath   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1'
            Shortcut   = @{
                Exe = "C:\Program Files\Microsoft VS Code\Code.exe"
            }
        }

        xInstallExe NodeJSLatestStable {
            Ensure     = 'Present'
            Arguments  = '/I C:\Sources\Software\NodeJS\LatestStable\node-LatestStable-x64.msi /q'
            AppName    = 'NodeJSLatestStable'
            BinaryPath = 'C:\windows\system32\msiexec.exe'
            ExitCodes  = @(0, 3010)
            TestPath   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F62C0E94-FBB4-4009-9941-6271BD2EBCEF}'
        }

        xInstallExe Git {
            Ensure     = 'Present'
            Arguments  = '/VERYSILENT'
            AppName    = 'Git'
            BinaryPath = 'C:\Sources\Software\Git\setup.exe'
            ExitCodes  = @(0, 3010)
            TestPath   = 'HKLM:\SOFTWARE\GitForWindows'
        }

        xInstallExe GoogleChrome {
            Ensure     = 'Present'
            Arguments  = '/i C:\Sources\Software\Google_Chrome\GoogleChromeStandaloneEnterprise64.msi /q'
            AppName    = 'Google Chrome'
            BinaryPath = 'C:\Windows\System32\msiexec.exe'
            ExitCodes  = @(0)
            TestPath   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A9EACB46-9179-3C2D-A196-62006713EC8E}'
        }

        Script RebootDEV {
            TestScript = {
                return (Test-Path HKLM:\SOFTWARE\DSC\RebootDEV)
            }
            SetScript  = {
                New-Item -Path HKLM:\SOFTWARE\DSC\RebootDEV -Force
                $global:DSCMachineStatus = 1 
            }
            GetScript  = { 
                return @{
                    Result = $(Test-Path "HKLM:\SOFTWARE\DSC\RebootDEV")
                }
            }
        }
    }

    # Install any explicitly added applications
    Node $AllNodes.Where({ $_.Applications -ne $null -and $_.Applications.Count -ne 0 }).NodeName {

        $node.Applications.foreach({
                xInstallExe $($_.AppName) {
                    Ensure     = 'Present'
                    AppName    = $($_.AppName)
                    Arguments  = $($_.Arguments)
                    BinaryPath = $($_.BinaryPath)
                    ExitCodes  = $($_.ExitCodes)
                    TestPath   = $($_.TestPath)
                }
            })
    }
}