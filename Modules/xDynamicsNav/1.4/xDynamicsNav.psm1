enum Ensure {
    Absent
    Present
}

[DscResource()]
class xNavSetup {
    [DscProperty(Key)]
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SetupPath

    [DscProperty()]
    [string]$ConfigFile

    [DscProperty()]
    [PSCredential]$ServiceAccount

    [DscProperty()]
    [string]$DatabaseServer

    [DscProperty()]
    [string]$DatabaseInstance

    [DscProperty()]
    [string]$DatabaseName

    [DscProperty()]
    [string]$InstanceName

    [DscProperty(Mandatory)]
    [string]$ManagementServicesPort

    [DscProperty(Mandatory)]
    [string]$ClientServicesPort
         
    [DscProperty(Mandatory)]
    [string]$WebServiceServerPort

    [DscProperty(Mandatory)]
    [string]$DataServiceServerPort

    [DscProperty()]
    [string[]]$SuperUser

    [DscProperty()]
    [string]$PatchPath

    [DscProperty(NotConfigurable)]
    [bool]$Compliant


    [void] Set() {

        if ($this.Ensure -eq [Ensure]::Present) {

            if ($this.ConfigFile -eq $null) {

                if ($this.InstanceName -eq $null) {
                    Write-Verbose "Setting InstanceName to DynamicsNAV100"
                    $this.InstanceName = "DynamicsNAV100"
                }

                if ($this.ServiceAccount -eq $null) {
                    Write-Verbose "Setting ServiceAccount to NT AUTHORITY\NETWORK SERVICE"
                    $this.ServiceAccount = [PSCredential]::new("NT AUTHORITY\NETWORK SERVICE", [SecureString]::new())
                }

                if ($this.ManagementServicesPort -eq $null) {
                    Write-Verbose "Setting ManagementServicesPort to 7045"
                    $this.ManagementServicesPort = "12045"
                }

                if ($this.ClientServicesPort -eq $null) {
                    Write-Verbose "Setting ClientServicesPort to 7046"
                    $this.ClientServicesPort = "12046"
                }

                if ($this.WebServiceServerPort -eq $null) {
                    Write-Verbose "Setting WebServiceServerPort to 7047"
                    $this.WebServiceServerPort = "12047"
                }

                if ($this.DataServiceServerPort -eq $null) {
                    Write-Verbose "Setting DataServiceServerPort to 7048"
                    $this.DataServiceServerPort = "12048"
                }

                $this.ConfigFile = $($env:TEMP + "\NavConfig.xml")
                $this.copyConfigFile($this)
            }
            
            if ($this.installNav($this)) {

                if ($this.PatchPath -ne $null) {
                    
                    $this.patchNav($this)
                }
                else {
                    
                    Set-Service -Name "MicrosoftDynamicsNavServer`$$($this.InstanceName)" -StartupType Automatic -Verbose -PassThru | Write-Verbose
                    Get-Service -Name "MicrosoftDynamicsNavServer`$$($this.InstanceName)" | Start-Service -Verbose -PassThru | Write-Verbose
                }

                if ($this.SuperUser -ne $null) {

                    $this.CreateSuperUser($this.SuperUser)
                }
            }
        }
        
    }
    
    [bool] Test() {
        return $(Test-Path "C:\Program Files (x86)\Microsoft Dynamics NAV\100\RoleTailored Client\Microsoft.Dynamics.Nav.Client.exe")        
    }

    [xNavSetup] Get() {
        $results = @{}
        
        if (!$this.ConfigFile) {
            $this.ConfigFile = $($env:TEMP + "\NavConfig.xml")
        }
        if (!$this.InstanceName) {
            $this.InstanceName = "DynamicsNAV100"
        }
        if (!$this.ServiceAccount) {
            $this.ServiceAccount = [PSCredential]::new("NT AUTHORITY\NETWORK SERVICE", [SecureString]::new())
        }

        $results['Ensure'] = $this.Ensure
        $results['SetupPath'] = $this.SetupPath
        $results['Compliant'] = $(Test-Path "C:\Program Files (x86)\Microsoft Dynamics NAV\100\RoleTailored Client\Microsoft.Dynamics.Nav.Client.exe")
        $results['ConfigFile'] = $this.ConfigFile
        $results['InstanceName'] = $this.InstanceName
        $results['ServiceAccount'] = $this.ServiceAccount.UserName

        return $results
    }

    [void] copyConfigFile([xNavSetup]$obj) {

        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($obj.ServiceAccount.Password)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
       
        $Config = @"
<Configuration>
    <Component Id="ClickOnceInstallerTools" State="Absent" ShowOptionNode="yes"/>
    <Component Id="NavHelpServer" State="Absent" ShowOptionNode="yes"/>
    <Component Id="WebClient" State="Absent" ShowOptionNode="yes"/>
    <Component Id="AutomatedDataCaptureSystem" State="Absent" ShowOptionNode="yes"/>
    <Component Id="OutlookAddIn" State="Absent" ShowOptionNode="yes"/>
    <Component Id="SQLServerDatabase" State="Absent" ShowOptionNode="yes"/>
    <Component Id="SQLDemoDatabase" State="Absent" ShowOptionNode="yes"/>
    <Component Id="ServiceTier" State="Local" ShowOptionNode="yes"/>
    <Component Id="Pagetest" State="Local" ShowOptionNode="yes"/>
    <Component Id="STOutlookIntegration" State="Local" ShowOptionNode="yes"/>
    <Component Id="ServerManager" State="Local" ShowOptionNode="yes"/>
    <Component Id="RoleTailoredClient" State="Local" ShowOptionNode="yes"/>
    <Component Id="ExcelAddin" State="Local" ShowOptionNode="yes"/>
    <Component Id="ClassicClient" State="Local" ShowOptionNode="yes"/>
    <Parameter Id="TargetPath" Value="C:\Program Files (x86)\Microsoft Dynamics NAV\100"/>
    <Parameter Id="TargetPathX64" Value="C:\Program Files\Microsoft Dynamics NAV\100"/>
    <Parameter Id="NavServiceServerName" Value="localhost"/>
    <Parameter Id="NavServiceInstanceName" Value="$($obj.InstanceName)"/>
    <Parameter Id="NavServiceAccount" Value="$($obj.ServiceAccount.UserName.Replace(".\", $($env:COMPUTERNAME + "\")))"/>
    <Parameter Id="NavServiceAccountPassword" IsHidden="yes" Value="$($PlainPassword)"/>
    <Parameter Id="ManagementServiceServerPort" Value="$($obj.ManagementServicesPort)"/>
    <Parameter Id="ManagementServiceFirewallOption" Value="false"/>
    <Parameter Id="NavServiceClientServicesPort" Value="$($obj.ClientServicesPort)"/>
    <Parameter Id="WebServiceServerPort" Value="$($obj.WebServiceServerPort)"/>
    <Parameter Id="WebServiceServerEnabled" Value="false"/>
    <Parameter Id="DataServiceServerPort" Value="$($obj.DataServiceServerPort)"/>
    <Parameter Id="DataServiceServerEnabled" Value="false"/>
    <Parameter Id="NavFirewallOption" Value="true"/>
    <Parameter Id="CredentialTypeOption" Value="Windows"/>
    <Parameter Id="DnsIdentity" Value=""/>
    <Parameter Id="ACSUri" Value=""/>
    <Parameter Id="SQLServer" Value="$($obj.DatabaseServer)"/>
    <Parameter Id="SQLInstanceName" Value="$($obj.DatabaseInstance)"/>
    <Parameter Id="SQLDatabaseName" Value="$($obj.DatabaseName)"/>
    <Parameter Id="SQLReplaceDb" Value="FAILINSTALLATION"/>
    <Parameter Id="SQLAddLicense" Value="true"/>
    <Parameter Id="PostponeServerStartup" Value="true"/>
    <Parameter Id="PublicODataBaseUrl" Value=""/>
    <Parameter Id="PublicSOAPBaseUrl" Value=""/>
    <Parameter Id="PublicWebBaseUrl" Value=""/>
    <Parameter Id="PublicWinBaseUrl" Value=""/>
    <Parameter Id="WebServerPort" Value="8080"/>
    <Parameter Id="WebServerSSLCertificateThumbprint" Value=""/>
    <Parameter Id="WebClientRunDemo" Value="true"/>
    <Parameter Id="WebClientDependencyBehavior" Value="install"/>
    <Parameter Id="NavHelpServerPath" Value="[WIX_SystemDrive]\Inetpub\wwwroot"/>
    <Parameter Id="NavHelpServerName" Value=""/>
    <Parameter Id="NavHelpServerPort" Value=""/>
</Configuration>
"@

        $Config | Out-File -FilePath $obj.ConfigFile -Encoding utf8 -Force

    }

    [bool] installNav([xNavSetup]$obj) {
        if ((Test-Path $obj.SetupPath) -and (Test-Path $obj.ConfigFile)) {

            $setup = Start-Process -FilePath $(Join-Path $obj.SetupPath "setup.exe") -ArgumentList  "/config", $obj.ConfigFile, "/quiet", "/log", "C:\Windows\Temp\NavInstallLog.log" -NoNewWindow -Wait -PassThru

            if ($setup.ExitCode -in @(0, 3010)) {

                Write-Verbose -Message $("Nav successfully installed. Exit Code " + $setup.ExitCode)
                return $true
            }
            else {

                Write-Verbose -Message ("Setup terminated with Exit Code " + $setup.ExitCode)
                throw $("Setup terminated with Exit Code " + $setup.ExitCode)
            }
        }
        else {
            Write-Verbose -Message $("SetupPath or ConfigFile not found!")
            throw $("SetupPath or ConfigFile not found!")
        }
        
        return $false
       
    }

    [void] patchNav([xNavSetup]$obj) {

        try {

            Write-Verbose -Message $("Patching NAV")
            Write-Verbose -Message $("Stopping Services:")
            Get-Service -Name "MicrosoftDynamicsNavServer`$*" | Set-Service -StartupType Disabled -Verbose -PassThru | select -ExpandProperty Name | Write-Verbose
            Get-Service -Name "MicrosoftDynamicsNavServer`$*" | Stop-Service -Force  -Verbose -PassThru | select -ExpandProperty Name | Write-Verbose

            Write-Verbose -Message $("Stopping Processes:")
            Get-Process -Name "*NAV*" | Stop-Process -Force -ea 0 -PassThru | select -ExpandProperty ProcessName | Write-Verbose
            Get-Process -Name "*finsql*" | Stop-Process -Force -ea 0 -PassThru | select -ExpandProperty ProcessName | Write-Verbose
            Get-Process -Name "*MMC*" | Stop-Process -Force -ea 0 -PassThru | select -ExpandProperty ProcessName | Write-Verbose
        }
        catch {

            Write-Verbose -Message "Konnte den NAV Service nicht beenden"
            return
        }

        #Patchen
        Write-Verbose -Message "Patching RTC"
        Copy-Item -Path "$($obj.PatchPath)\RTC\*" -Destination "C:\Program Files (x86)\Microsoft Dynamics NAV\100\RoleTailored Client" -Force -Recurse -PassThru -ErrorAction Continue #| Write-Verbose
        Write-Verbose -Message "Patching NST"
        Copy-Item -Path "$($obj.PatchPath)\NST\*" -Destination "C:\Program Files\Microsoft Dynamics NAV\100\Service" -Exclude "CustomSettings.config" -ErrorAction Continue -Force -Recurse -PassThru #| Write-Verbose

        #Start Service
        Write-Verbose -Message "Starting Services:"

        
        foreach ($serv in (Get-Service -Name "MicrosoftDynamicsNavServer`$*")) {

            Get-Service -Name $serv.Name | Set-Service -StartupType Automatic -Verbose -PassThru | select -ExpandProperty Name | Write-Verbose	
            Start-Process -FilePath C:\windows\system32\cmd.exe -ArgumentList "/c", "sc.exe", "config", $($serv.Name), "start=auto" -Wait -PassThru
            Get-Service -Name $serv.Name | Start-Service -PassThru -Verbose -ea 0 | select -ExpandProperty Name |  Write-Verbose
        }


        if ($obj.InstanceName -ne "DynamicsNAV100") {

            Write-Verbose -Message "Upgrading Database"
            Start-Process -FilePath 'C:\Program Files\Microsoft Dynamics NAV\100\Service\finsql.exe' -ArgumentList "Command=Upgradedatabase,", $("Database=" + $($obj.InstanceName) + ","), "ServerName=$($env:COMPUTERNAME + "\" + $obj.DatabaseInstance)," -ErrorAction SilentlyContinue -Wait -PassThru | Write-Verbose
        }

        Write-Verbose -Message "Done"
    }

    [void] CreateSuperUser([string[]]$superUser) {

        #Import Module
        Get-Module -Name "*Microsoft.Dynamics.Nav*" | Remove-Module -Force | Out-Null

        Import-Module 'C:\Program Files\Microsoft Dynamics NAV\100\Service\Microsoft.Dynamics.Nav.Management.dll' -Force | Out-Null

        foreach ($user in $superUser) {

            $sup = $user.Replace(".\", "$($env:COMPUTERNAME)\")

            try {
                           
                Write-Verbose $("Berechtige " + $sup + " auf " + $this.InstanceName)
                New-NavServeruser -ServerInstance $this.InstanceName -WindowsAccount $sup
                New-NAVServerUserpermissionSet -permissionsetid SUPER -ServerInstance $this.InstanceName -WindowsAccount $sup
            }     
            catch {

                Write-Verbose $("Fehler beim berechtigen des Users " + $sup + ": " + $_.Exception.Message)
            }
        }  
    }
}

[DscResource()]
class xNavSetupOnCore {

    [DscProperty(Key)]
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SetupPath

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$HlinkDllPath

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$T2embedDllPath

    [DscProperty()]
    [string]$PatchPath

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseServer

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseInstance

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName

    [DscProperty(Mandatory)]
    [PSCredential]$ServiceAccount
    
    [DscProperty()]
    [string[]]$SuperUser

    [DscProperty(Mandatory)]
    [string]$ManagementServicesPort

    [DscProperty(Mandatory)]
    [string]$ClientServicesPort

    [DscProperty(Mandatory)]
    [string]$ODataServicesPort
     
    [DscProperty(Mandatory)]
    [string]$SOAPServicesPort

    [DscProperty(NotConfigurable)]
    [bool]$Compliant


    [void] Set() {

        if ($this.Ensure -eq [Ensure]::Present) {
            
            $this.InstallNav($this)

            if ($this.PatchPath -ne $null) {
                
                $this.PatchNav($this.PatchPath, $this.DatabaseName)
            } 

            if ($this.SuperUser -ne $null) {
            
                $this.CreateSuperUser($this.SuperUser)
            }
        }
    }
    
    [bool] Test() {
        return $(Test-Path "C:\Program Files\Microsoft Dynamics NAV\100\")
    }

    [xNavSetupOnCore] Get() {
        $results = @{}
        
        $results['Ensure'] = $this.Ensure
        $results['SetupPath'] = $this.SetupPath
        $results['PatchPath'] = $this.PatchPath
        $results['HlinkDllPath'] = $this.HlinkDllPath
        $results['T2embedDllPath'] = $this.T2embedDllPath
        $results['Compliant'] = $(Test-Path "C:\Program Files\Microsoft Dynamics NAV\100\")

        return $results
    }

    [void] InstallNAVSipCryptoProvider() {

        $sipPath = "C:\Windows\System32\NavSip.dll"
        Test-Path -Path $sipPath -ErrorAction Stop | Out-Null

        Write-Host "Installing SIP crypto provider: '$sipPath'"

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllCreateIndirectData\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPCreateIndirectData' -Force | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllGetCaps\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPGetCaps' -Force | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllGetSignedDataMsg\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPGetSignedDataMsg' -Force | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllIsMyFileType2\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPIsFileSupportedName' -Force | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllPutSignedDataMsg\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPPutSignedDataMsg' -Force | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllRemoveSignedDataMsg\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPRemoveSignedDataMsg' -Force | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography\OID\EncodingType 0\CryptSIPDllVerifyIndirectData\{36FFA03E-F824-48E7-8E07-4A2DCB034CC7}'
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'Dll' -Value $sipPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -PropertyType string -Name 'FuncName' -Value 'NavSIPVerifyIndirectData' -Force | Out-Null
    }

    [void] InstallNav([xNavSetupOnCore]$obj) {

        Write-Verbose "Installiere Prerequisites"
        Start-Process -FilePath ([System.IO.Path]::Combine($obj.SetupPath, 'Prerequisite Components\IIS URL Rewrite Module\rewrite_2.0_rtw_x64.msi')) -ArgumentList "/qn /norestart" -Wait
        Start-Process -FilePath ([System.IO.Path]::Combine($obj.SetupPath, 'Prerequisite Components\Microsoft Report Viewer\SQLSysClrTypes.msi')) -ArgumentList "/qn /norestart" -Wait
        Start-Process -FilePath ([System.IO.Path]::Combine($obj.SetupPath, 'Prerequisite Components\Microsoft Report Viewer\ReportViewer.msi')) -ArgumentList "/qn /norestart" -Wait
        Start-Process -FilePath ([System.IO.Path]::Combine($obj.SetupPath, 'Prerequisite Components\Open XML SDK 2.5 for Microsoft Office\OpenXMLSDKv25.msi')) -ArgumentList "/qn /norestart" -Wait
            
        Write-Verbose "Kopiere Service Tier files"
        Copy-Item -Path ([System.IO.Path]::Combine($obj.SetupPath, 'ServiceTier\Program Files')) -Destination "C:\" -Recurse -Force
        Copy-Item -Path ([System.IO.Path]::Combine($obj.SetupPath, 'ServiceTier\System64Folder\NavSip.dll')) -Destination "C:\Windows\System32\" -Force
        Copy-Item -Path ([System.IO.Path]::Combine($obj.SetupPath, 'ServiceTier\System64Folder\NavSip.dll')) -Destination "C:\Windows\SysWow64\" -Force

        Write-Verbose "Kopiere Add-ins"
        $serviceTierFolder = (Get-Item "C:\Program Files\Microsoft Dynamics NAV\100\Service").FullName
        $addinsDir = [System.IO.Path]::Combine($serviceTierFolder, 'Add-ins\Office')
        Get-ChildItem -Path ([System.IO.Path]::Combine($obj.SetupPath, 'RoleTailoredClient\Program Files\Microsoft Dynamics NAV')) -Recurse -Filter "*office*.dll" | % {

            Copy-Item -Path $_.FullName -Destination $addinsDir
        } 
        
        Write-Verbose "Kopiere DLLs"
        Copy-Item -Path ([System.IO.Path]::Combine($obj.SetupPath, 'RoleTailoredClient\systemFolder\NavSip.dll')) -Destination "C:\Windows\SysWow64\" -Force 
        Copy-Item -Path $obj.HlinkDllPath -Destination $serviceTierFolder
        
        Copy-Item -Path $obj.HlinkDllPath -Destination "c:\windows\system32\" -Force
        Copy-Item -Path $obj.HlinkDllPath -Destination "c:\windows\SysWow64\" -Force
        Copy-Item -Path $obj.T2embedDllPath -Destination "c:\windows\system32\" -Force
        Copy-Item -Path $obj.T2embedDllPath -Destination "c:\windows\SysWow64\" -Force

 
        Write-Verbose "Installiere Outlook Add-In"
        $setup = Start-Process -FilePath ([System.IO.Path]::Combine($obj.SetupPath, 'Installers\DE\OlAddin\OutlookAddIn.Local.De.msi')) -ArgumentList "/qn /norestart" -Wait -PassThru
        Write-Verbose "Exit code $($setup.ExitCode)"

        Write-Verbose "Installiere Service Tier"
        $setup = Start-Process -FilePath ([System.IO.Path]::Combine($obj.SetupPath, 'Installers\DE\Server\Server.Local.De.msi')) -ArgumentList "/qn /norestart" -Wait -PassThru
        Write-Verbose "Exit code $($setup.ExitCode)"

        Write-Verbose "Erstelle Server config"
        $CustomConfigFile = [System.IO.Path]::Combine($serviceTierFolder, 'CustomSettings.config')
        $CustomConfig = [xml](Get-Content $CustomConfigFile)

        $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value = $obj.DatabaseServer
        $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value = $obj.DatabaseInstance
        $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseName']").Value = $obj.DatabaseName
        $customConfig.SelectSingleNode("//appSettings/add[@key='ServerInstance']").Value = $obj.DatabaseName
        $customConfig.SelectSingleNode("//appSettings/add[@key='ManagementServicesPort']").Value = $this.ManagementServicesPort
        $customConfig.SelectSingleNode("//appSettings/add[@key='ClientServicesPort']").Value = $this.ClientServicesPort
        $customConfig.SelectSingleNode("//appSettings/add[@key='SOAPServicesPort']").Value = $this.SOAPServicesPort
        $customConfig.SelectSingleNode("//appSettings/add[@key='ODataServicesPort']").Value = $this.ODataServicesPort
        $customConfig.SelectSingleNode("//appSettings/add[@key='DefaultClient']").Value = "Windows" #hier war mal "Web"
        $taskSchedulerKeyExists = ($customConfig.SelectSingleNode("//appSettings/add[@key='EnableTaskScheduler']") -ne $null)
        if ($taskSchedulerKeyExists) {
            $customConfig.SelectSingleNode("//appSettings/add[@key='EnableTaskScheduler']").Value = "false"
        }

        $CustomConfig.Save($CustomConfigFile)


        Write-Verbose "Erstelle Service"
        $serverFile = ([System.IO.Path]::Combine($serviceTierFolder, "Microsoft.Dynamics.Nav.Server.exe"))
        $configFile = ([System.IO.Path]::Combine($serviceTierFolder, "Microsoft.Dynamics.Nav.Server.exe.config"))

        New-Service -Name "MicrosoftDynamicsNavServer`$$($obj.DatabaseName)" -BinaryPathName """$serverFile"" `$$($obj.DatabaseName) /config ""$configFile""" -DisplayName "Microsoft Dynamics NAV Server [$($obj.DatabaseName)]" -Description $obj.DatabaseName -StartupType Automatic -Credential $obj.ServiceAccount -DependsOn @("HTTP") | Out-Null

        Write-Verbose "Konfiguriere Registry"
        $serverVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($serverFile)
        $versionFolder = ("{0}{1}" -f $serverVersion.FileMajorPart,$serverVersion.FileMinorPart)
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\$versionFolder\Service"
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name 'Path' -Value "$serviceTierFolder\" -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name 'Installed' -Value 1 -Force | Out-Null

        $this.InstallNAVSipCryptoProvider()
    }

    [void] CreateSuperUser([string[]]$superUser) {

        #Import Module
        Get-Module -Name "*Microsoft.Dynamics.Nav*" | Remove-Module -Force | Out-Null

        Import-Module 'C:\Program Files\Microsoft Dynamics NAV\100\Service\Microsoft.Dynamics.Nav.Management.psm1' -Force | Out-Null

        foreach ($user in $superUser) {

            $sup = $user.Replace(".\", "$($env:COMPUTERNAME)\")

            try {
                           
                Write-Verbose $("Berechtige " + $sup + " auf " + $this.InstanceName)
                New-NavServeruser -ServerInstance $this.InstanceName -WindowsAccount $sup
                New-NAVServerUserpermissionSet -permissionsetid SUPER -ServerInstance $this.InstanceName -WindowsAccount $sup
            }     
            catch {

                Write-Verbose $("Fehler beim berechtigen des Users " + $sup + ": " + $_.Exception.Message)
            }
        }  
    }


    [void] PatchNav([xNavSetup]$obj) {

        "Stopping services and running processes" | out-file "$($env:TEMP)\navsetup.log" -Append
        ##Set-Service -Name $("MicrosoftDynamicsNavServer`$"+ $($obj.InstanceName)) -StartupType Automatic -Status Stopped

        Get-Service -Name "MicrosoftDynamicsNavServer`$*" | Set-Service -StartupType Automatic -Status Stopped -PassThru
        Get-Service -Name "MicrosoftDynamicsN*" | Stop-Service -Force -ea 0
        Get-Process -Name "*NAV*" | Stop-Process -Force -ea 0
        Get-Process -Name "*finsql*" | Stop-Process -Force -ea 0
        Get-Process -Name "*MMC*" | Stop-Process -Force -ea 0

        #Patchen
        Write-Verbose -Message "Patching NST"
        Copy-Item -Path "$($obj.Patchpath)\NST\*" -Destination "C:\Program Files\Microsoft Dynamics NAV\100\Service" -Exclude "CustomSettings.config" -Force -Recurse -PassThru

        #Start Service
        Write-Verbose "Starting Services"
    }
}

[DscResource()]
class xNavInstance {
    [DscProperty(Key)]
    [string]$InstanceName

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [PSCredential]$ServiceAccount

    [DscProperty()]
    [string[]]$SuperUser

    [DscProperty(Mandatory)]
    [string]$DatabaseServer

    [DscProperty(Mandatory)]
    [string]$DatabaseInstance

    [DscProperty(Mandatory)]
    [string]$DatabaseName

    [DscProperty(Mandatory)]
    [string]$ManagementServicesPort

    [DscProperty(Mandatory)]
    [string]$ClientServicesPort

    [DscProperty(Mandatory)]
    [string]$ODataServicesPort
     
    [DscProperty(Mandatory)]
    [string]$SOAPServicesPort

    [DscProperty(NotConfigurable)]
    [bool] $Compliant


    [void] Set() {
        if ($this.Ensure -eq [Ensure]::Present -and (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\100\Service')) {
            #Import Module
            $nstPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\100\Service'
            $managementDllPath = Join-Path (Get-ItemProperty -path $nstPath).Path '\Microsoft.Dynamics.Nav.Management.dll'
            Import-Module $managementDllPath -ErrorVariable errorVariable -ErrorAction SilentlyContinue -Force | Out-Null

            $instance = Get-NAVServerInstance -ServerInstance $this.InstanceName -Force

            if ($instance) {
                Write-Verbose $("Found Instance " + $instance.ServerInstance + ". Trying to adjust it")
                
                try {
                    #Set Instance
                    Set-NAVServerInstance -ServerInstance $this.InstanceName -ServiceAccountCredential $this.ServiceAccount -ServiceAccount User -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName DatabaseServer -KeyValue $this.DatabaseServer -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName DatabaseInstance -KeyValue $this.DatabaseInstance -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName DatabaseName -KeyValue $this.DatabaseName -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName ClientServicesPort -KeyValue $this.ClientServicesPort -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName ManagementServicesPort -KeyValue $this.ManagementServicesPort -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName ODataServicesPort -KeyValue $this.ODataServicesPort -Confirm:$false
                    Set-NAVServerConfiguration -ServerInstance $this.InstanceName -KeyName SOAPServicesPort -KeyValue $this.SOAPServicesPort -Confirm:$false
                }
                catch {
                    Write-Verbose $("Fehler beim anpassen der Instanz: " + $_.Exception.Message)
                    throw $("Fehler beim erstellen der Instanz: " + $_.Exception.Message)
                }
            }
            else {
                Write-Verbose $("Creating new Instance " + $this.InstanceName + ".")

                #Create Instance
                try {
                    New-NAVServerInstance -ServerInstance $this.InstanceName -ManagementServicesPort $this.ManagementServicesPort -ClientServicesPort $this.ClientServicesPort -ODataServicesPort $this.ODataServicesPort -SOAPServicesPort $this.SOAPServicesPort -ServiceAccount User -ServiceAccountCredential $this.ServiceAccount -DatabaseServer $this.DatabaseServer -DatabaseInstance $this.DatabaseInstance -DatabaseName $this.DatabaseName -Force -Confirm:$false
                }
                catch {
                    Write-Verbose $("Fehler beim erstellen der Instanz per New-NavserverInstance: " + $_.Exception.Message)
                    throw $("Fehler beim erstellen der Instanz per New-NavserverInstance: " + $_.Exception.Message)
                }
                try {
                    Set-NAVServerInstance -ServerInstance $this.InstanceName -ServiceAccountCredential $this.ServiceAccount -ServiceAccount User -Confirm:$false
                }
                catch {
                    Write-Verbose $("Fehler beim einstellen der Instanz Credentials per Set-NavserverInstance: " + $_.Exception.Message)
                    throw $("Fehler beim einstellen der Instanz Credentials per Set-NavserverInstance: " + $_.Exception.Message)
                }
                try {
                    Write-Verbose $("Starte Datenbank Update")
                    Start-Process -FilePath 'C:\Program Files\Microsoft Dynamics NAV\100\Service\finsql.exe' -ArgumentList "Command=Upgradedatabase,", $("Database=" + $this.DatabaseName + ","), "ServerName=LOCALHOST," -Wait -PassThru 
                }
                catch {
                    Write-Verbose $("Fehler beim Upgraden der Datenbank per finsql.exe: " + $_.Exception.Message)
                    throw $("Fehler beim Upgraden der Datenbank per finsql.exe: " + $_.Exception.Message)
                }
                try {
                    Start-Service -Name $('MicrosoftDynamicsNavServer$' + $this.InstanceName)
                }
                catch {
                    Write-Verbose $("Fehler beim Starten des Dienstes: " + $_.Exception.Message)
                }
             
                foreach ($user in $this.SuperUser) {

                    $sup = $null
                    $sup = $user.Replace(".\", "$($env:COMPUTERNAME)\")

                    try {
                           
                        Write-Verbose $("Berechtige " + $sup + " auf " + $this.InstanceName)
                        New-NavServeruser -ServerInstance $this.InstanceName -WindowsAccount $sup
                        New-NAVServerUserpermissionSet -permissionsetid SUPER -ServerInstance $this.InstanceName -WindowsAccount $sup
                    }     
                    catch {

                        Write-Verbose $("Fehler beim berechtigen des Users " + $sup + ": " + $_.Exception.Message)
                    }
                }           
            }

            $myArgs = 'config "{0}" start=auto' -f $('MicrosoftDynamicsNavServer$' + $this.InstanceName)
            Start-Process -FilePath sc.exe -ArgumentList $myArgs
        }        
    }        
    

    [bool] Test() {        
        return $this.testCompliance($this)
    }    

    [xNavInstance] Get() {
        $this.Compliant = $this.testCompliance($this)        
        return $this 
    }
    
    [bool] testCompliance([xNavInstance]$obj) {
        #Import Module
        $nstPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\100\Service'
        $managementDllPath = Join-Path (Get-ItemProperty -path $nstPath).Path -ChildPath '\Microsoft.Dynamics.Nav.Management.dll'
        Import-Module $managementDllPath -ErrorVariable errorVariable -ErrorAction SilentlyContinue -Force | Out-Null

        $return = $false

        Get-NAVServerInstance -ServerInstance $obj.InstanceName -Force | % {
            if (!$return) {
                $return = $true
            }
        }

        return $return
    }    
}

enum ImportAction {
    Overwrite
}

enum SynchronizeSchemaChanges {
    Force
}

[DscResource()]
class xNavImportObjects {

    [DscProperty(Key)]
    [string]$objectPath
    
    [DscProperty(Mandatory)]
    [string]$DatabaseName

    [DscProperty(Mandatory)]
    [string]$DatabaseServerInstance

    [DscProperty(Mandatory)]
    [string]$NavServerName

    [DscProperty(Mandatory)]
    [string]$NavServerInstance

    [DscProperty(Mandatory)]
    [string]$NavServerManagementPort

    [DscProperty(Mandatory)]
    [ImportAction]$ImportAction

    [DscProperty(Mandatory)]
    [SynchronizeSchemaChanges]$SynchronizeSchemaChanges

    [DscProperty(Mandatory)]
    [string]$LogPath

    [DscProperty(NotConfigurable)]
    [bool] $Compliant

    [void] Set() {        

        Start-Process -FilePath 'C:\Program Files\Microsoft Dynamics NAV\100\Service\finsql.exe' -ArgumentList "Command=ImportObjects,ImportAction=Overwrite,SynchronizeSchemaChanges=$($this.SynchronizeSchemaChanges),", "File=$($this.objectPath),", "LogFile=$($this.LogPath),", "ServerName=$($this.DatabaseServerInstance),", "Database=$($this.DatabaseName)," , "NavServerName=$($this.NavServerName),", "NavServerInstance=$($this.NavServerInstance),", "NavServerManagementPort=$($this.NavServerManagementPort)" -ErrorAction SilentlyContinue -Wait -PassThru
        
        New-Item -Path HKLM:\SOFTWARE -Name DSC -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path HKLM:\SOFTWARE\DSC -Name xNavImportObjects -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path HKLM:\SOFTWARE\DSC\xNavImportObjects\ -Name (Split-Path -Path $this.objectPath -Leaf) -PropertyType DWORD -Value 1 -ErrorAction SilentlyContinue | Out-Null

    }        

    [bool] Test() {
        return $this.testCompliance((Split-Path $this.objectPath -Leaf))
    }    

    [xNavImportObjects] Get() {        
        $this.Compliant = $this.testCompliance((Split-Path $this.objectPath -Leaf))
        return $this 
    }   
    
    [bool] testCompliance ([string]$objectName) {

        if (Get-ItemProperty -Path HKLM:\SOFTWARE\DSC\xNavImportObjects -Name $objectName -ErrorAction SilentlyContinue) {
            
            if ((Get-ItemPropertyValue -Path HKLM:\SOFTWARE\dsc\xNavImportObjects -Name $objectName -ErrorAction SilentlyContinue) -eq 1) {
                return $true
            }

        }
        return $false

    }
}

[DscResource()]
class xNavClientDefaults {

    [DscProperty(Key)]
    [string]$InstanceName

    [DscProperty(Mandatory)]
    [string]$ClientServicesPort
    

    [void] Set()
    {       
        $xml = New-Object System.XML.XMLDocument
        $xml.Load("C:\programdata\microsoft\Microsoft Dynamics NAV\100\ClientUserSettings.config")

        $xml.configuration.appSettings.ChildNodes[5].value = $this.InstanceName
        $xml.configuration.appSettings.ChildNodes[3].value = $this.ClientServicesPort

        $xml.Save("C:\programdata\microsoft\Microsoft Dynamics NAV\100\ClientUserSettings.config")
    }        
    

    [bool] Test()
    {        
        #return $($this.isCompliant($this))

        $xml = New-Object System.XML.XMLDocument
        $xml.Load("C:\programdata\microsoft\Microsoft Dynamics NAV\100\ClientUserSettings.config")

        if (($xml.configuration.appSettings.ChildNodes.Where({$_.Key -eq "ClientServicesPort"}).Value -eq $this.ClientServicesPort) -and `
            ($xml.configuration.appSettings.ChildNodes.Where({$_.Key -eq "ServerInstance"}).Value -eq $this.InstanceName)) {

            return $true
        }
        else {

            return $false
        }
    }    

    [xNavClientDefaults] Get()
    {        
        $results = @{}

        $results['InstanceName'] = $this.InstanceName
        $results['ClientServicesPort'] = $this.ClientServicesPort

        return $results
    }    

}

[DscResource()]
class xBCSetup {
    [DscProperty(Key)]
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SetupPath

    [DscProperty()]
    [string]$ConfigFile

    [DscProperty()]
    [PSCredential]$ServiceAccount

    [DscProperty()]
    [string]$DatabaseServer

    [DscProperty()]
    [string]$DatabaseInstance

    [DscProperty()]
    [string]$DatabaseName

    [DscProperty()]
    [string]$InstanceName

    [DscProperty(Mandatory)]
    [string]$ManagementServicesPort

    [DscProperty(Mandatory)]
    [string]$ClientServicesPort

    [DscProperty(Mandatory)]
    [string]$DataServicesPort
    
    [DscProperty()]
    [string]$LicenseFile

    [DscProperty()]
    [string[]]$SuperUser

    [DscProperty(NotConfigurable)]
    [bool]$Compliant


    [void] Set() {

        if ($this.Ensure -eq [Ensure]::Present) {

            if (!$this.ConfigFile) {

                if (!$this.InstanceName) {
                    Write-Verbose "Setting InstanceName to DynamicsNAV140"
                    $this.InstanceName = "DynamicsNAV140"
                }

                if (!$this.ServiceAccount) {
                    Write-Verbose "Setting ServiceAccount to NT AUTHORITY\NETWORK SERVICE"
                    $this.ServiceAccount = [PSCredential]::new("NT AUTHORITY\NETWORK SERVICE", [SecureString]::new())
                }

                $this.ConfigFile = $($env:TEMP + "\BcConfig.xml")
                $this.copyConfigFile($this)
            }
            
            if ($this.installNav($this)) {
                                
                Set-Service -Name "MicrosoftDynamicsNavServer`$$($this.InstanceName)" -StartupType Automatic -Verbose -PassThru | Write-Verbose
                Get-Service -Name "MicrosoftDynamicsNavServer`$$($this.InstanceName)" | Start-Service -Verbose -PassThru | Write-Verbose
                
                if ($this.LicenseFile -ne $null) {

                    $this.ImportLicenseFile()
                }

                if ($this.SuperUser -ne $null) {

                    $this.CreateSuperUser()
                }
            }
        }
        
    }
    
    [bool] Test() {
        return $(Test-Path "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\140")        
    }

    [xBCSetup] Get() {
        $results = @{}
        
        if (!$this.ConfigFile) {
            $this.ConfigFile = $($env:TEMP + "\BcConfig.xml")
        }
        if (!$this.InstanceName) {
            $this.InstanceName = "DynamicsNAV140"
        }
        if (!$this.ServiceAccount) {
            $this.ServiceAccount = [PSCredential]::new("NT AUTHORITY\NETWORK SERVICE", [SecureString]::new())
        }

        $results['Ensure'] = $this.Ensure
        $results['SetupPath'] = $this.SetupPath
        $results['Compliant'] = $(Test-Path "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\140")
        $results['ConfigFile'] = $this.ConfigFile
        $results['InstanceName'] = $this.InstanceName
        $results['ServiceAccount'] = $this.ServiceAccount.UserName.Replace(".\", $($env:COMPUTERNAME + "\"))

        return $results
    }

    [void] copyConfigFile([xBCSetup]$obj) {

        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($obj.ServiceAccount.Password)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
       
        $Config = @"
<Configuration>
	<Component Id="RoleTailoredClient" State="Local" ShowOptionNode="yes"/>
	<Component Id="ExcelAddin" State="Local" ShowOptionNode="yes"/>
	<Component Id="ClassicClient" State="Local" ShowOptionNode="yes"/>
	<Component Id="ClickOnceInstallerTools" State="Absent" ShowOptionNode="yes"/>
	<Component Id="NavHelpServer" State="Absent" ShowOptionNode="yes"/>
	<Component Id="WebClient" State="Local" ShowOptionNode="yes"/>
	<Component Id="AutomatedDataCaptureSystem" State="Absent" ShowOptionNode="yes"/>
	<Component Id="OutlookAddIn" State="Absent" ShowOptionNode="yes"/>
	<Component Id="SQLServerDatabase" State="Absent" ShowOptionNode="yes"/>
	<Component Id="SQLDemoDatabase" State="Absent" ShowOptionNode="yes"/>
	<Component Id="ServiceTier" State="Local" ShowOptionNode="yes"/>
	<Component Id="Pagetest" State="Local" ShowOptionNode="yes"/>
	<Component Id="STOutlookIntegration" State="Local" ShowOptionNode="yes"/>
	<Component Id="ServerManager" State="Local" ShowOptionNode="yes"/>
	<Component Id="DevelopmentEnvironment" State="Local" ShowOptionNode="yes"/>
	<Parameter Id="TargetPath" Value="C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\140"/>
	<Parameter Id="TargetPathX64" Value="C:\Program Files\Microsoft Dynamics 365 Business Central\140"/>
	<Parameter Id="NavServiceServerName" Value="localhost"/>
	<Parameter Id="NavServiceInstanceName" Value="$($obj.InstanceName)"/>
	<Parameter Id="NavServiceAccount" Value="$($obj.ServiceAccount.UserName.Replace(".\", $($env:COMPUTERNAME + "\")))"/>
	<Parameter Id="NavServiceAccountPassword" IsHidden="yes" Value="$($PlainPassword)"/>
	<Parameter Id="ServiceCertificateThumbprint" Value=""/>
	<Parameter Id="ManagementServiceServerPort" Value="$($this.ManagementServicesPort)"/>
	<Parameter Id="ManagementServiceFirewallOption" Value="false"/>
	<Parameter Id="NavServiceClientServicesPort" Value="$($this.ClientServicesPort)"/>
	<Parameter Id="WebServiceServerPort" Value="13047"/>
	<Parameter Id="WebServiceServerEnabled" Value="false"/>
	<Parameter Id="DataServiceServerPort" Value="$($this.DataServicesPort)"/>
	<Parameter Id="DataServiceServerEnabled" Value="false"/>
	<Parameter Id="DeveloperServiceServerPort" Value="13049"/>
	<Parameter Id="DeveloperServiceServerEnabled" Value="true"/>
	<Parameter Id="NavFirewallOption" Value="true"/>
	<Parameter Id="CredentialTypeOption" Value="Windows"/>
	<Parameter Id="DnsIdentity" Value=""/>
	<Parameter Id="ACSUri" Value=""/>
	<Parameter Id="SQLServer" Value="$($obj.DatabaseServer)"/>
	<Parameter Id="SQLInstanceName" Value="$($obj.DatabaseInstance)"/>
	<Parameter Id="SQLDatabaseName" Value="$($obj.DatabaseName)"/>
	<Parameter Id="SQLReplaceDb" Value="FAILINSTALLATION"/>
	<Parameter Id="SQLAddLicense" Value="true"/>
	<Parameter Id="PostponeServerStartup" Value="false"/>
	<Parameter Id="PublicODataBaseUrl" Value=""/>
	<Parameter Id="PublicSOAPBaseUrl" Value=""/>
	<Parameter Id="PublicWebBaseUrl" Value=""/>
	<Parameter Id="PublicWinBaseUrl" Value=""/>
	<Parameter Id="WebServerPort" Value="8080"/>
	<Parameter Id="WebServerSSLCertificateThumbprint" Value=""/>
	<Parameter Id="WebClientRunDemo" Value="true"/>
	<Parameter Id="WebClientDependencyBehavior" Value="install"/>
	<Parameter Id="NavHelpServerPath" Value="[WIX_SystemDrive]\Inetpub\wwwroot"/>
	<Parameter Id="NavHelpServerName" Value="$($env:computername)"/>
	<Parameter Id="NavHelpServerPort" Value="49000"/>
</Configuration>

"@

        $Config | Out-File -FilePath $obj.ConfigFile -Encoding utf8 -Force

    }

    [bool] installNav([xBCSetup]$obj) {

        if ((Test-Path $obj.SetupPath) -and (Test-Path $obj.ConfigFile)) {
        
            $setup = Start-Process -FilePath $(Join-Path $obj.SetupPath "setup.exe") -ArgumentList  "/config", $obj.ConfigFile, "/quiet", "/log", "C:\Windows\Temp\NavInstallLog.log" -NoNewWindow -Wait -PassThru

            if ($setup.ExitCode -in @(0, 3010)) {

                "Nav successfully installed. Exit Code " + $setup.ExitCode | out-file "$($env:TEMP)\bcsetup.log" -Append
                Write-Verbose -Message ("Nav successfully installed. Exit Code " + $setup.ExitCode)
                return $true
            }
            else {

                Write-Verbose -Message ("Setup terminated with Exit Code " + $setup.ExitCode)
                throw ("Setup terminated with Exit Code " + $setup.ExitCode)
            }
        }
        else {
            Write-Verbose -Message ("SetupPath or ConfigFile not found!")
            throw ("SetupPath or ConfigFile not found!")
        }
        
        return $false
       
    }

    [void] ImportLicenseFile() {
    
        #Import Module
        Get-Module -Name "*Microsoft.Dynamics.Nav*" | Remove-Module -Force

        Import-Module 'C:\Program Files\Microsoft Dynamics 365 Business Central\140\Service\Microsoft.Dynamics.Nav.Management.dll' -Force | Out-Null

        Write-Verbose "Importing Licensefile $($this.LicenseFile)"
        Import-NAVServerLicense -LicenseFile $this.LicenseFile -ServerInstance $this.InstanceName
    }


    [void] CreateSuperUser() {

        #Import Module
        Get-Module -Name "*Microsoft.Dynamics.Nav*" | Remove-Module -Force

        Import-Module 'C:\Program Files\Microsoft Dynamics 365 Business Central\140\Service\Microsoft.Dynamics.Nav.Management.dll' -Force | Out-Null

        foreach ($user in $this.SuperUser) {

            $sup = $user.Replace(".\", "$($env:COMPUTERNAME)\")

            try {

                Write-Verbose $("Berechtige " + $sup + " auf " + $this.InstanceName)
                New-NavServeruser -ServerInstance $this.InstanceName -WindowsAccount $sup
                New-NAVServerUserpermissionSet -permissionsetid SUPER -ServerInstance $this.InstanceName -WindowsAccount $sup
            }     
            catch {

                Write-Verbose $("Fehler beim berechtigen des Users " + $sup + ": " + $_.Exception.Message)
            }
        }  
    }
}
