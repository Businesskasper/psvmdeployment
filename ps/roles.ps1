$NodeRoles = [Hashtable]::new()
$Applications = [Hashtable]::new()

$Applications.SSMS = [Application]@{

    AppName = 'SQL Server Management Studio 18.0'
    Arguments = @('/s')
    BinaryPath = 'C:\Sources\Software\Microsoft_SSMS\SSMS-Setup-ENU.exe'
    ExitCodes = @(0, 3010)
    InstallType = [InstallType]::EXE
    SourcePath = @{
        Source      = [System.IO.Path]::Combine($global:root, "Sources", "Software", "Microsoft_SSMS")
        Destination = 'C:\Sources\Software\Microsoft_SSMS\'
    }
    Shortcut = @{
        Exe = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
    }
    TestPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{673f06b0-3fd3-4b11-a775-3359fa5df604}'
}

$Applications.VSPro2019 = [Application]@{

    AppName = 'Visual Studio 2019 Professional'
    Arguments = @('C:\Sources\Software\Microsoft_VS_2019_Professional\install.ps1')
    BinaryPath = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
    ExitCodes = @(0, 3010)
    InstallType = [InstallType]::EXE
    SourcePath = @{
        Source      = [System.IO.Path]::Combine($global:root, 'Sources', 'Software', 'Microsoft_VS_2019_Professional')
        Destination = 'C:\Sources\Software\Microsoft_VS_2019_Professional\'
    }
    Shortcut   = @{
        Exe       = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe"
    }
    TestPath = 'hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\83d3efc7'
}

$Applications.VSCode = [Application]@{

    Arguments = 'C:\Sources\Software\Microsoft_VS_Code\install.ps1'
    AppName = 'VS Code 2019'
    BinaryPath = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
    ExitCodes = @(0, 3010)
    InstallType = [InstallType]::EXE
    SourcePath = @{
        Source      = [System.IO.Path]::Combine($global:root, 'Sources', 'Software', 'Microsoft_VS_Code')
        Destination = 'C:\Sources\Software\Microsoft_VS_Code\'
    }
    Shortcut   = @{
        Exe       = "C:\Program Files\Microsoft VS Code\Code.exe"
    }
    TestPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1'
}

$Applications.BeyondCompare = [Application]@{

    AppName = 'Beyond Compare 4'
    Arguments = @('/i', 'C:\Sources\Software\BeyondCompare\BCompare-4.2.4.22795_x64.msi', '/q')
    BinaryPath = 'C:\windows\system32\msiexec.exe'
    ExitCodes  = @(0)
    InstallType = [InstallType]::MSI
    Shortcut   = @{
        Exe       = "C:\Program Files\Beyond Compare 4\BCompare.exe"
        Parameter = ""
    }
    SourcePath = @{
        Source      = [System.IO.Path]::Combine($global:root, 'Sources', 'Software', 'BeyondCompare')
        Destination = 'C:\Sources\Software\BeyondCompare\'
    }
    TestPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{382FD58E-226F-418B-8F34-DA8EE89D9550}'
}


$Applications.BC = [Application]@{

    
}


$NodeRoles.VM = [NodeRole]@{

    Name = "VM"

    DscModules = @(

        [DscModule]@{
            Name = 'ComputerManagementDsc' 
            RequiredVersion = [Version]::new(6, 3, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xInstallExe' 
            RequiredVersion = [Version]::new(1, 2)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xWinEventLog' 
            RequiredVersion = [Version]::new(1, 2, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xDSCHelper' 
            RequiredVersion = [Version]::new(1, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xRemoteDesktopAdmin' 
            RequiredVersion = [Version]::new(1, 1, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xNetworking' 
            RequiredVersion = [Version]::new(5, 5, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xActiveDirectory'
            RequiredVersion = [Version]::new(2, 22, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        }
    )

    Files =  @(
    )
}

$NodeRoles.DC = [NodeRole]@{

    Name = "DC"

    Applications = @()

    DscModules = @(
    
        [DscModule]@{
            Name = 'xActiveDirectory' 
            RequiredVersion = [Version]::new(2, 22, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xDhcpServer' 
            RequiredVersion = [Version]::new(1, 6, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xDnsServer' 
            RequiredVersion = [Version]::new(1, 11, 0, 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        }
    )
}

$NodeRoles.SQL = [NodeRole]@{

    Name = "SQL"

    DscModules = @(

        [DscModule]@{

            Name = "SqlServer"
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
            RequiredVersion = [Version]::new(21, 1, 18221)
        },
        [DscModule]@{
            Name = 'SqlServerDSC'
            RequiredVersion = [Version]::new(11, 0, 0 , 0)
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        }

    )

    Files =  @(

        @{
            Source      = [System.IO.Path]::Combine($global:root, 'Sources', 'Software', 'Microsoft_SQL_Server_2019_Standard')
            Destination = 'C:\Sources\SQL\Microsoft_SQL_Server_2019_Standard\'
        }
    )

    Applications = @($Applications.SSMS)
}

$NodeRoles.DEV = [NodeRole]@{

    Name = "DEV"

    Applications = @($Applications.BeyondCompare, $Applications.VSCode, $Applications.VSPro2019)

    DscModules = @(
    
        [DscModule]@{
            Name = 'xNodeJS'
            RequiredVersion = '1.0'
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        }
    )

    Files =  @(
    )
}

$NodeRoles.BC = [NodeRole]@{

    Name = "BC"

    Applications = @($Applications.Newsystem)

    DscModules = @(
        
        [DscModule]@{
            Name = 'SqlServerDSC'
            RequiredVersion = '11.0.0.0'
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'SqlServer'
            RequiredVersion = '21.1.18068'
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        },
        [DscModule]@{
            Name = 'xDynamicsNav'
            #RequiredVersion = '1.3'
            RequiredVersion = '1.4'
            ModuleBase = [System.IO.Path]::Combine($global:root, 'modules')
        }
    )

    Files = @(
        
        @{
            Source      = [System.IO.Path]::Combine($global:root, 'Sources', 'BC', 'Database')
            Destination = 'C:\SQL\Backup\'
        },
        @{
            Source      = [System.IO.Path]::Combine($global:root, 'Sources', 'Software', 'Microsoft_Dynamics365_SpringRelease')
            Destination = 'C:\Sources\BC\Microsoft_Dynamics365_SpringRelease'
        }
    )
}

$NodeRoles.Keys | % {

    $NodeRoles[$_].Validate()
}