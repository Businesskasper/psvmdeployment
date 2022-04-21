$Applications = @{
    GoogleChrome       = [Application]@{
        AppName    = "Google Chrome"
        Arguments  = "/i C:\Sources\Software\Google_Chrome\GoogleChromeStandaloneEnterprise64.msi /q"
        BinaryPath = "C:\Windows\System32\msiexec.exe"
        ExitCodes  = @(0)
        SourcePath = @{
            Source      = "$($global:root)\Sources\Software\Google_Chrome"
            Destination = "C:\Sources\Software\Google_Chrome\"
        }
        TestPath   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A9EACB46-9179-3C2D-A196-62006713EC8E}"
    }
    SSMS               = [Application]@{
        AppName     = "SQL Server Management Studio 18.0"
        Arguments   = @("/s")
        BinaryPath  = "C:\Sources\Software\Microsoft_SSMS\SSMS-Setup-ENU.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::EXE
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\Microsoft_SSMS"
            Destination = "C:\Sources\Software\Microsoft_SSMS\"
        }
        Shortcut    = @{
            Exe = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
        }
        TestPath    = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{673f06b0-3fd3-4b11-a775-3359fa5df604}"
    }
    VSPro2019          = [Application]@{
        AppName     = "Visual Studio 2019 Professional"
        Arguments   = @("C:\Sources\Software\Microsoft_VS_2019_Professional\install.ps1")
        BinaryPath  = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::EXE
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\Microsoft_VS_2019_Professional"
            Destination = "C:\Sources\Software\Microsoft_VS_2019_Professional\"
        }
        Shortcut    = @{
            Exe = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe"
        }
        TestPath    = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\83d3efc7"
    }
    VSCode             = [Application]@{
        Arguments   = "C:\Sources\Software\Microsoft_VS_Code\install.ps1"
        AppName     = "VS Code 2019"
        BinaryPath  = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::EXE
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\Microsoft_VS_Code"
            Destination = "C:\Sources\Software\Microsoft_VS_Code\"
        }
        Shortcut    = @{
            Exe = "C:\Program Files\Microsoft VS Code\Code.exe"
        }
        TestPath    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1"
    }
    NodeJSLatestStable = [Application]@{
        Arguments   = "/I C:\Sources\Software\NodeJS\LatestStable\node-LatestStable-x64.msi /q"
        AppName     = "NodeJSLatestStable"
        BinaryPath  = "C:\windows\system32\msiexec.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::MSI
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\NodeJS\LatestStable"
            Destination = "C:\Sources\Software\NodeJS\LatestStable\"
        }
        TestPath    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F62C0E94-FBB4-4009-9941-6271BD2EBCEF}"
    }
    Git                = [Application]@{
        Arguments   = "/VERYSILENT"
        AppName     = "Git"
        BinaryPath  = "C:\Sources\Software\Git\setup.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::EXE
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\Git"
            Destination = "C:\Sources\Software\Git\"
        }
        TestPath    = "HKLM:\SOFTWARE\GitForWindows"
    }
    MSSQL2019DEV       = [Application]@{
        Arguments   = "/Action=Install /FEATURES=SQLEngine /INSTANCENAME=MSSQLSERVER /SkipRules=RebootRequiredCheck /SQLSYSADMINACCOUNTS=Administrator /IAcceptSqlServerLicenseTerms /Q"
        AppName     = "MSSQL2019DEV"
        BinaryPath  = "C:\Sources\Software\Microsoft_SQL_Server_2019_Developer\setup.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::EXE
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\Microsoft_SQL_Server_2019_Developer"
            Destination = "C:\Sources\Software\Microsoft_SQL_Server_2019_Developer\"
        }
        TestPath    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft SQL Server SQL2019"
    }
}

$NodeRoles = @{
    VM  = [NodeRole]@{
        Name       = "VM"
        DscModules = @(
            [PsModule]@{
                Name            = "ComputerManagementDsc" 
                RequiredVersion = [Version]::new(6, 3, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xInstallExe" 
                RequiredVersion = [Version]::new(1, 2)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xWinEventLog" 
                RequiredVersion = [Version]::new(1, 2, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xDSCHelper" 
                RequiredVersion = [Version]::new(1, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xRemoteDesktopAdmin" 
                RequiredVersion = [Version]::new(1, 1, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xNetworking" 
                RequiredVersion = [Version]::new(5, 5, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xActiveDirectory"
                RequiredVersion = [Version]::new(2, 22, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            }
        )
        Files      = @()
    }
    DC  = [NodeRole]@{
        Name         = "DC"
        Applications = @()
        DscModules   = @(
            [PsModule]@{
                Name            = "xActiveDirectory" 
                RequiredVersion = [Version]::new(2, 22, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xDhcpServer" 
                RequiredVersion = [Version]::new(1, 6, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            },
            [PsModule]@{
                Name            = "xDnsServer" 
                RequiredVersion = [Version]::new(1, 11, 0, 0)
                ModuleBase      = "$($global:root)\modules"
            }
        )
    }
    SQL = [NodeRole]@{
        Name         = "SQL"
        DscModules   = @(
            [PsModule]@{
                Name            = "SqlServer"
                ModuleBase      = "$($global:root)\modules"
                RequiredVersion = [Version]::new(21, 1, 18068)
            },
            [PsModule]@{
                Name            = "SqlServerDSC"
                RequiredVersion = [Version]::new(11, 0, 0 , 0)
                ModuleBase      = "$($global:root)\modules"
            }
        )
        Files = @(
            [Binary]@{
                Source      = "$($global:root)\Sources\Software\Microsoft_SQL_Server_2019_Developer"
                Destination = "C:\Sources\Software\Microsoft_SQL_Server_2019_Developer\"
            },
            [Binary]@{
                Source      = "$($global:root)\Sources\Software\Microsoft_SSMS"
                Destination = "C:\Sources\Software\Microsoft_SSMS\"
            }
        )
        Applications = @()
    }
    DEV = [NodeRole]@{
        Name         = "DEV"
        Files        = @(
            @{
                Source      = "$($global:root)\Sources\Software\Google_Chrome"
                Destination = "C:\Sources\Software\Google_Chrome\"
            },
            @{
                Source      = "$($global:root)\Sources\Software\Microsoft_SSMS"
                Destination = "C:\Sources\Software\Microsoft_SSMS\"
            },
            @{
                Source      = "$($global:root)\Sources\Software\Microsoft_VS_2019_Professional"
                Destination = "C:\Sources\Software\Microsoft_VS_2019_Professional\"
            },
            @{
                Source      = "$($global:root)\Sources\Software\Microsoft_VS_Code"
                Destination = "C:\Sources\Software\Microsoft_VS_Code\"
            },
            @{
                Source      = "$($global:root)\Sources\Software\NodeJS\LatestStable"
                Destination = "C:\Sources\Software\NodeJS\LatestStable\"
            },
            @{
                Source      = "$($global:root)\Sources\Software\Git"
                Destination = "C:\Sources\Software\Git\"
            },
            @{
                Source      = "$($global:root)\Sources\Software\Microsoft_SQL_Server_2019_Developer"
                Destination = "C:\Sources\Software\Microsoft_SQL_Server_2019_Developer\"
            }
        )
        Applications = @()
        DscModules   = @(
            [PsModule]@{
                Name            = "xNodeJS"
                RequiredVersion = "1.0"
                ModuleBase      = "$($global:root)\modules"
            }
        )
    }
}

# Check if required files are present
foreach ($roleName in $NodeRoles.Keys) {
    try {
        $NodeRoles[$roleName].Validate()
    }
    catch {
        Write-Host "Validation for $($NodeRoles[$roleName].Name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

foreach ($appName in $Applications.Keys) {
    try {
        $Applications[$appName].Validate()
    }
    catch {
        Write-Host "Validation for $($Applications[$appName].Name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

