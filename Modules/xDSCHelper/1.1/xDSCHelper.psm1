enum RoleStatus {
    Present
    Absent
}

[DscResource()]
class xLogRole
{
    [DscProperty(Key)]
    [string]$Role
    
    [void] Set()
    {
        $key = 'HKLM:\SOFTWARE\DSC\NodeRole'
        $property = $this.Role
        
        New-Item -Path $key -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $key -Name $property -PropertyType String | Out-Null
    }        
    
    [bool] Test()
    {        
        return $this.isCompliant($this)
    }    

    [xLogRole] Get()
    {        
        $result = @{}
        $result['Role'] = $this.Role

        return $result 
    } 
    
    [bool] isCompliant([xLogRole]$obj) {
    
        $key = 'HKLM:\SOFTWARE\DSC\NodeRole'
        $property = $obj.Role

        if ((Test-Path $key) -and (Get-ItemProperty -Path $key -Name $property -ErrorAction SilentlyContinue)) {
            return $true
        }

        return $false

    }   
}

[DscResource()]
class xLogRoleStatus
{
    [DscProperty(Key)]
    [string]$Role

    [DscProperty(Mandatory)]
    [RoleStatus]$Status
    
    [void] Set()
    {
        $key = 'HKLM:\SOFTWARE\DSC\NodeRole'
        $property = $this.Role
        $value = $this.Status
        
        New-Item -Path $key -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $key -Name $property -PropertyType String -Value $value -Force | Out-Null
    }        
    
    [bool] Test()
    {        
        return $this.isCompliant($this)
    }    

    [xLogRoleStatus] Get()
    {        
        $result = @{}

        if ($this.isCompliant($this)) {
            $endStatus = [RoleStatus]::Present
        }
        else {
            $endStatus = [RoleStatus]::Absent
        }

        $result['Role'] = $this.Role
        $result['Status'] = $endStatus

        return $result 
    } 
    
    [bool] isCompliant([xLogRoleStatus]$obj) {
    
        $key = 'HKLM:\SOFTWARE\DSC\NodeRole'
        $property = $obj.Role
        $value = $obj.Status

        if ((Test-Path $key) -and (Get-ItemPropertyValue -Path $key -Name $property) -eq $value) {
            return $true
        }

        return $false

    }   
}

[DscResource()]
class xVmNetConfig
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$NicName

    [DscProperty()]
    [string] $IPAddress

    [DscProperty()]
    [string] $PrefixLength

    [DscProperty()]
    [string] $DNSAddress

    [DscProperty()]
    [bool] $DHCP
        
    [void] Set()
    {        
        $adapter = Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | ? {$_.DisplayValue -eq $this.NicName} | select -ExpandProperty Name

        if ($this.DHCP) {

            Set-NetIPInterface -InterfaceAlias $adapter -Dhcp Enabled
            Set-DnsClientServerAddress -InterfaceAlias $adapter -ResetServerAddresses 
        }
        else {

            Get-NetIPAddress -InterfaceAlias $adapter | ? {$_.AddressFamily -ne "IPv6"} | Remove-NetIPAddress -Confirm:$false
            New-NetIPAddress –InterfaceAlias $adapter –IPAddress $this.IPAddress –PrefixLength $this.PrefixLength -AddressFamily IPv4

            Set-DnsClientServerAddress -InterfaceAlias $adapter -ResetServerAddresses
            Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses @($this.DNSAddress) 
        }

    }        
    
    [bool] Test()
    {        
        $adapter = Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | ? {$_.DisplayValue -eq $this.NicName} | select -ExpandProperty Name

        if (($this.DHCP -and ((Get-NetIPInterface -InterfaceAlias $adapter).Dhcp -eq "Enabled")) -or `                    ((Get-NetIPAddress -InterfaceAlias $adapter -AddressFamily IPv4 | select -ExpandProperty IPAddress) -eq $this.IPAddress -and `        (Get-NetIPAddress -InterfaceAlias $adapter -AddressFamily IPv4 | select -ExpandProperty PrefixLength) -eq $this.PrefixLength -and `        (Get-DnsClientServerAddress -InterfaceAlias $adapter -AddressFamily IPv4 | select -ExpandProperty ServerAddresses) -contains $this.DNSAddress)) {
        
            return $true
        }
        else {

            return $false
        }
    }    
    
    [xVmNetConfig] Get()
    {        
        return $this
    }    
}

[DscResource()]
class xJoinDomain {

    [DscProperty(Key)]
    [string]$DomainName

    [DscProperty()]
    [PSCredential]$JoinCredential

    [void] Set()
    {        
        Add-Computer -DomainName $this.DomainName -Credential $this.JoinCredential
    }        
    
    [bool] Test()
    {        
        return (Get-WmiObject Win32_ComputerSystem).Domain -eq $this.DomainName
    }    
    
    [xJoinDomain] Get()
    {        
        return $this
    }    
}


function Write-InformationLog([string]$source, [System.Diagnostics.EventLogEntryType]$entryType, [string]$message) {
    
    New-EventLog –LogName Application –Source $source -ErrorAction SilentlyContinue
    Write-EventLog -LogName Application -Source $source -EntryType $entryType -EventId 1337 -Message $message
}

[DscResource()]
class xRestoreSqlDatabase
{
    [DscProperty(Key)]
    [string]$Role

    [DscProperty(Mandatory)]
    [string]$Server

    [DscProperty(Mandatory)]
    [string]$Instance

    [DscProperty(Mandatory)]
    [string]$BackupPath

    [DscProperty(Mandatory)]
    [string]$DatabaseName

    [DscProperty()]
    [PSCredential]$SqlUser

    [Microsoft.SqlServer.Management.Smo.SqlSmoObject] $ServerConnection

    
    [void] Set() {

        $this.ConnectToServer()
        
        $dataFolder = $this.ServerConnection.Settings.DefaultFile
        $logFolder = $this.ServerConnection.Settings.DefaultLog

        if ($dataFolder.Length -eq 0)
        {
            $dataFolder = $this.ServerConnection.Information.MasterDBPath
        }

        if ($logFolder.Length -eq 0) 
        {
            $logFolder = $this.ServerConnection.Information.MasterDBLogPath
        }

        $backupDeviceItem = [Microsoft.SqlServer.Management.Smo.BackupDeviceItem]::new($this.BackupPath, 'File')

        $restore = [Microsoft.SqlServer.Management.Smo.Restore]@{ Database = $this.DatabaseName }
        $restore.Devices.Add($backupDeviceItem)

        $dataFileNumber = 0

        foreach ($file in $restore.ReadFileList($this.ServerConnection)) {

            $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]@{ LogicalFileName = $file.LogicalName }

            if ($file.Type -eq 'D') {

                if($dataFileNumber -ge 1) {

                    $suffix = $dataFileNumber.ToString()
                }
                else {

                    $suffix = $null
                }

                $relocateFile.PhysicalFileName = [System.IO.Path]::Combine($dataFolder, $this.DatabaseName + $suffix + ".mdf")

                $dataFileNumber ++;
            }
            else {

                $relocateFile.PhysicalFileName = [System.IO.Path]::Combine($logFolder, $this.DatabaseName + ".ldf")
            }

            $restore.RelocateFiles.Add($relocateFile) | out-null
        }    

        $restore.SqlRestore($this.ServerConnection)
    }

    [bool] Test() {
        
        return $this.IsCompliant()
    }

    [xRestoreSqlDatabase] Get() {

        return $this
    }

    [void] ConnectToServer() {

        if ($this.ServerConnection -ne $null) {
            
            return
        }

        [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.Smo")

        if ((Get-Module -Name sqlps) -eq $null) {
            
            throw [Exception]::new("Could not load Sql Module")
        }

        try {

            if ($this.Instance -eq $null -or $this.Instance -eq "" -or $this.Instance.ToUpper() -eq "MSSQLServer") {

                $ServerInstance = $this.Server
            }
            else {

                $ServerInstance = $this.Server + "\" + $this.Instance
            }

            if($this.SqlUser -eq $null) {

                $this.ServerConnection = [Microsoft.SqlServer.Management.Smo.Server]::new($ServerInstance)
            }
            else {

                $this.ServerConnection = [Microsoft.SqlServer.Management.Smo.Server]::new($Serverinstance, $this.SqlUser.UserName, $this.SqlUser.Password)
            }
        }
        catch {

            Write-Host "Could not connect to Sql Server Instance"
            throw
        }
    }

    [bool] IsCompliant () {

        $this.ConnectToServer()
        return $this.ServerConnection.Databases.Where( {$_.Name -eq $this.DatabaseName} ).Count -eq 1
    }
}