function Deploy-VM {

    param (

        [Parameter(Position = 1)]
        [string]$vmName,

        [Parameter(Position = 2)]
        [string]$vhdxFile,

        [Parameter(Position = 3)]
        [Array]$nics,
   
        [Parameter(Position = 4)]
        [string]$dscFile,

        [Parameter(Position = 5)]
        [PsModule[]]$psModules,

        [Parameter(Position = 6)]
        [string]$organization,

        [Parameter(Position = 7)]
        [switch]$enableDSCReboot,

        [Parameter(Position = 8)]
        [Array]$files,

        [Parameter(Position = 9)]
        [int64]$ram,

        [Parameter(Position = 10)]
        [int64]$diskSize,

        [Parameter(Position = 11)]
        [int64]$cores,

        [Parameter(Position = 12)]
        [string]$systemLocale,

        [Parameter(Position = 13)]
        [bool]$online
    )

    #
    # Preparation
    #

    # Load Hyper-V module
    try {

        Import-Module Hyper-V -ErrorAction Stop | Out-Null
    }
    catch {

        Write-Host "Could not load Hyper-V module!" -ForegroundColor Red
        throw $_.Exception
    }

    # Test Hyper-V connection
    try {

        $vmHost = Get-VMHost
    }
    catch {

        Write-Host "Could not connect to Hyper-V host" -ForegroundColor Red
        throw $_.Exception
    }

    # Create .vhdx directory
    $vmVhdDir = Join-Path -Path $vmHost.VirtualHardDiskPath -ChildPath $vmName
    
    Write-Host "Creating $($vmVhdDir)"
    DeleteItem -path $vmVhdDir
    New-Item -Path $vmVhdDir -ItemType Directory -ErrorAction Stop | Out-Null



    #
    # Create VHD
    #

    # Generate Answerfile
    $answerFile = @"
<?xml version="1.0"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
	<settings xmlns="urn:schemas-microsoft-com:unattend" pass="oobeSystem">
		<component name="Microsoft-Windows-Shell-Setup" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<OOBE>
				<SkipUserOOBE>true</SkipUserOOBE>
				<NetworkLocation>Work</NetworkLocation>
				<ProtectYourPC>1</ProtectYourPC>
				<SkipMachineOOBE>true</SkipMachineOOBE>
				<HideEULAPage>true</HideEULAPage>
			</OOBE>
			<TimeZone>W. Europe Standard Time</TimeZone>
			<RegisteredOrganization>$organization</RegisteredOrganization>
			<UserAccounts>
				<AdministratorPassword>
					<Value>UABhAHMAcwB3ADAAcgBkAEEAZABtAGkAbgBpAHMAdAByAGEAdABvAHIAUABhAHMAcwB3AG8AcgBkAAAA</Value>
					<PlainText>false</PlainText>
				</AdministratorPassword>
			</UserAccounts>
			<RegisteredOwner>Administrator</RegisteredOwner>
		</component>
		<component name="Microsoft-Windows-International-Core" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<SystemLocale>$systemLocale</SystemLocale>
            <UserLocale>$systemLocale</UserLocale>
            <InputLocale>0407:00000407</InputLocale>
		</component>
	</settings>
	<settings xmlns="urn:schemas-microsoft-com:unattend" pass="specialize">
		<component name="Microsoft-Windows-Deployment" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<RunSynchronous>
				<RunSynchronousCommand><Order>1</Order>
					<Description>disable user account page</Description>
					<Path>reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Setup\OOBE /v UnattendCreatedUser /t REG_DWORD /d 1 /f</Path>
				</RunSynchronousCommand>
			</RunSynchronous>
		</component>
		<component name="Microsoft-Windows-Shell-Setup" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<ComputerName>$vmName</ComputerName>
		</component>
	</settings>
</unattend>
"@
    
    
    # Copy template .vhdx
    $vmVHDPath = [System.IO.Path]::Combine($vmVhdDir, $vmName + ".vhdx")
    Write-Host "Copying $($vhdxFile) to $($vmVHDPath)"
    Copy-Item -Path $vhdxFile -Destination $vmVHDPath -Force -ErrorAction Stop | Out-Null
    

    # Resize .vhdx
    Write-Host "Expanding $($vmVHDPath) to $($diskSize / 1GB)GB"
    Resize-VHD -Path $vmVHDPath -SizeBytes $diskSize -ErrorAction Stop
        
        
    # Mount .vhdx
    Write-Host "Mounting $($drive.Root) => $($vmVHDPath)"

    $before = Get-PSDrive
    Mount-VHD -Path $vmVHDPath
    $drive = Compare-Object -ReferenceObject $before -DifferenceObject $(Get-PSDrive) | select -ExpandProperty InputObject 

    if ($drive.Count -gt 1) {

        $drive = ($drive | sort Used)[1]
    }


    # Expand partition
    $maxSize = (Get-PartitionSupportedSize -DriveLetter $($drive.Name)).SizeMax 
    $maxSizeRounded = [math]::floor($maxSize / 1GB) * 1GB
    Write-Host "Expanding $($drive.Root) to $($maxSizeRounded / 1GB) GB"
    Resize-Partition -DriveLetter $($drive.Name) -Size $maxSizeRounded -ErrorAction Stop


    # Generate Answerfile and copy to .vhdx
    Write-Host "Copying unattended file"
    New-Item -Path $(Join-Path -Path ($drive.Root) -ChildPath Windows\Panther) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    $answerFile | Out-File -FilePath $(Join-Path -Path ($drive.Root) -ChildPath Windows\Panther\Unattend.xml) -Force
        
    # Copy DSC .mof file to .vhdx
    $dscFileTarget = Join-Path -Path ($drive.Root) -ChildPath '\Windows\System32\Configuration\Pending.mof'
    if ($dscFile) { 

        Write-Host "Copying DSC configuration $($dscFile) to $($dscFileTarget))"
        Copy-Item -Path $dscFile -Destination $dscFileTarget -ErrorAction Stop            
    }



    #
    # VM Preparation
    #

    # Copy modules to .vhdx
    Write-Host "Copying modules"

    $psModules | % {

        if ($_) {

            Write-Host "Copying $([System.IO.Path]::Combine($_.ModuleBase, $_.Name, $_.RequiredVersion)) to $([System.IO.Path]::Combine(($drive.Root), "Program Files\WindowsPowerShell\Modules", $_.Name, $_.RequiredVersion))"
            Copy-Item -Path ([System.IO.Path]::Combine($_.ModuleBase, $_.Name, $_.RequiredVersion)) `
                      -Destination ([System.IO.Path]::Combine(($drive.Root), "Program Files\WindowsPowerShell\Modules", $_.Name, $_.RequiredVersion)) `
                      -Recurse -Force -ErrorAction Stop | Out-Null
        }
    }


    # Copy files to .vhdx
    Write-Host "Copying files" 
        
    $files | % {

        if ($_) {

            Write-Host "Copying $($_.Source) to $($_.Destination.Replace($_.Destination.Split("\")[0], $drive.Name + ":" ))"
            Copy-Item -Path $($_.Source) `
                      -Destination $($_.Destination.Replace($_.Destination.Split("\")[0], $drive.Name + ":" )) `
                      -Force -Recurse -ErrorAction Stop  | Out-Null
        }
    }
        

    # Copy DSC meta config
    if ($enableDSCReboot) {

        Write-Host "Copying DSC meta config to $(Join-Path -Path ($drive.Root) -ChildPath 'Windows\System32\Configuration\MetaConfig.mof')"

        $dscMetaConfig = @'
/*
@TargetNode='localhost'
@GeneratedBy=Administrator
@GenerationDate=02/12/2018 16:30:16
@GenerationHost=ITKitchen-Server5
*/

instance of MSFT_DSCMetaConfiguration as $MSFT_DSCMetaConfiguration1ref
{
 RefreshFrequencyMins = 30;
 RefreshMode = "Push";
 RebootNodeIfNeeded = True;

};

instance of OMI_ConfigurationDocument
{
 Version="2.0.0";
 MinimumCompatibleVersion = "1.0.0";
 CompatibleVersionAdditionalProperties= { "MSFT_DSCMetaConfiguration:StatusRetentionTimeInDays" };
 Author="Administrator";
 GenerationDate="02/12/2018 16:30:16";
 GenerationHost="ITKitchen-Server5";
 Name="LCM";
};
'@
        $dscMetaConfig | Out-File $(Join-Path -Path ($drive.Root) -ChildPath 'Windows\System32\Configuration\MetaConfig.mof') -Force
    }


    # Unmount .vhdx
    Write-Host "Unmounting $($drive.Root) => $($vmVHDPath)"
    Dismount-VHD -Path $vmVHDPath



    #
    # VM creation
    #

    # Create and launch VM
    Write-Host "Creating and launching $($vmName)"

    $vm = New-VM -Name $vmName -MemoryStartupBytes $ram -VHDPath $vmVHDPath -Generation 2 -BootDevice VHD
    $vm | Get-VMNetworkAdapter | Remove-VMNetworkAdapter -ErrorAction Stop | Out-Null
    Set-VM -VM $vm -ProcessorCount $cores -ErrorAction Stop
    Get-VMIntegrationService -VM $vm | Enable-VMIntegrationService

    foreach ($nic in $nics) {

        Add-VMNetworkAdapter -VM $vm -SwitchName $nic.SwitchName -Name $nic.SwitchName -DeviceNaming On -ErrorAction Stop | Out-Null
    }

    if ($online) {

        $defaultSwitch = Get-VMSwitch -Id "c08cb7b8-9b3c-408e-8e30-5e16a3aeb444"
        Add-VMNetworkAdapter -VM $vm -SwitchName $defaultSwitch.Name -Name "Online" -DeviceNaming On | Out-Null
    }
            
    Start-VM -VM $vm | Out-Null
}


function New-VMNic ([string]$name, [Microsoft.HyperV.PowerShell.VMSwitchType]$type, [string]$nic) {

    Import-Module Hyper-V

    if (-not (Get-VMSwitch -Name $name -SwitchType $type -ErrorAction SilentlyContinue)) {

        Write-Host "Creating virtual switch $($name)"
        if ($type -eq [Microsoft.HyperV.PowerShell.VMSwitchType]::External -and $nic -ne $null) {

            New-VMSwitch -Name $name -NetAdapterName $nic 
        }
        else {

            New-VMSwitch -Name $name -SwitchType $type | Out-Null
        }
    }
}

function Show-VMLog ([string]$vmName, [PSCredential]$cred) {

    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open()


    $code = {

        Param
        (
            [string]$vmName,
            [pscredential]$credentials
        )

        Add-Type –assemblyName PresentationFramework

        #Build the GUI
        [xml]$xaml = @"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
Height="500" Width="800" Topmost="False">
<Grid>
    <Grid.RowDefinitions>
		<RowDefinition Height="*" />
		<RowDefinition Height="40" />
	</Grid.RowDefinitions>
    <DataGrid 
        AutoGenerateColumns="False" 
        HorizontalAlignment="Stretch" 
        x:Name="dataGrid1" 
        VerticalAlignment="Stretch" 
        Grid.Row="0"
        HeadersVisibility="All" 
        IsReadOnly="True"
        >
        <DataGrid.Columns>
            <DataGridTextColumn Header="TimeCreated"
                            Binding="{Binding TimeCreated}" 
                            />
            <DataGridTextColumn Header="Message"
                            Binding="{Binding Message}"
                            Width="*" 
                            />
        </DataGrid.Columns>
    </DataGrid >
    <!--<Button x:Name="btn_Refresh" Content="Refresh" HorizontalAlignment="Right" VerticalAlignment="Center" Width="85" Grid.Row="1" Margin="0,5,5,5"/>-->
    <Label x:Name="lbl_WaitingForMachine" Content="warte auf Maschine... :)" Visibility="Visible" Grid.Row="1" Margin="0,5,5,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
    <Ellipse x:Name="ellipse_Status" Width="15" Height="15" Fill="Red" Grid.Row="1" HorizontalAlignment="Left" Margin="5,5,0,5"/> 
</Grid>
</Window> 
"@

        function RefreshEvents {
    
            param([Hashtable]$syncHash, [string]$vmName, [PSCredential]$credentials)
    
            $syncHash.Host = $host

            $NestedRunspace = [runspacefactory]::CreateRunspace()
            $NestedRunspace.ApartmentState = "STA"
            $NestedRunspace.ThreadOptions = "ReuseThread"
            $NestedRunspace.Open()

            $NestedRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash) 
            $NestedRunspace.SessionStateProxy.SetVariable("vmName", $vmName)
            $NestedRunspace.SessionStateProxy.SetVariable("credentials", $credentials)
 
            $nestedCode = {

                while ($true) {    

                    $reachable = $false
                    
                    try {
                    
                        $Events = Invoke-Command -VMName $vmName -Credential $credentials -ScriptBlock {Get-WinEvent -LogName microsoft-windows-dsc/analytic -Oldest | select TimeCreated, Message | sort TimeCreated -Descending} -ErrorAction Stop 
                        $syncHash.Window.Dispatcher.invoke([action] { 
                                $syncHash.dataGrid1.ItemsSource = $Events
                                $syncHash.lbl_WaitingForMachine.Visibility = 'Hidden' 
                            })
                        $reachable = $true

                    }
                    catch {

                        $syncHash.Window.Dispatcher.invoke([action] {                         
                                $syncHash.lbl_WaitingForMachine.Visibility = 'Visible' 
                                $syncHash.ellipse_Status.Fill = 'Red'
                            })
                        start-sleep -seconds 5
                    }

                    if ($reachable -eq $true) {

                        try {
                            if ((Invoke-Command -VMName $vmName -Credential $credentials -ScriptBlock {Get-DscConfigurationStatus | select -ExpandProperty Status} -ErrorAction Stop) -eq "Success" ) {

                                $syncHash.Window.Dispatcher.invoke([action] { 
                                        $syncHash.ellipse_Status.Fill = 'Green'
                                    })
                            }
                            else {

                                $syncHash.Window.Dispatcher.invoke([action] { 
                                        $syncHash.ellipse_Status.Fill = 'Red'
                                    })
                            }
                        }
                        catch {

                            $syncHash.Window.Dispatcher.invoke([action] { 
                                    $syncHash.ellipse_Status.Fill = 'Red'
                                })
                        }
                    }
                }                    
            }

            $PSinstance = [powershell]::Create().AddScript($nestedCode)
            $PSinstance.Runspace = $NestedRunspace
            $nestedJob = $PSinstance.BeginInvoke()

        } 

        # XAML objects 
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $syncHash = [hashtable]::Synchronized(@{})
        $syncHash.Window = [Windows.Markup.XamlReader]::Load($reader)

        $syncHash.dataGrid1 = $syncHash.Window.FindName("dataGrid1")
        $syncHash.lbl_WaitingForMachine = $syncHash.Window.FindName("lbl_WaitingForMachine")
        $syncHash.ellipse_Status = $syncHash.Window.FindName("ellipse_Status")
            
        RefreshEvents -syncHash $syncHash -vmName $vmName -credentials $credentials

        $syncHash.Window.Title = "Deploymentstatus $vmName"
        $syncHash.Window.ShowDialog()
        $syncHash.Window.Activate()
        $NestedRunspace.Close()
        $NestedRunspace.Dispose()
    }

    $PSinstance1 = [powershell]::Create().AddScript($Code)
    $PSinstance1.AddArgument($vmName) | Out-Null
    $PSinstance1.AddArgument($cred) | out-null
    $PSinstance1.Runspace = $Runspace

    return $PSinstance1.BeginInvoke()
}

function GetNicTask([hashtable[]]$nics) {

    $returnString += @"
Import-Module xDscHelper

"@

    foreach ($nic in ($nics | ? {$_.IPAddress})) {

$returnString += @"
#Updating $($nic.SwitchName)


`$adapter = Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | ? {`$_.DisplayValue -eq "$($nic.SwitchName)"} | select -ExpandProperty Name
Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Found adapter `$(`$adapter)"


if (`$$($nic.DHCP)) {

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Enabling DHCP on `$(`$adapter)"    
    Set-NetIPInterface -InterfaceAlias `$adapter -Dhcp Enabled

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Resetting DNS on `$(`$adapter)"    
    Set-DnsClientServerAddress -InterfaceAlias `$adapter -ResetServerAddresses 
}
elseif ((Get-NetIPAddress -InterfaceAlias `$adapter | ? {`$_.AddressFamily -ne "IPv6"}).IPAddress -ne "$($nic.IPAddress)") {

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Removing addresses on `$(`$adapter)"    
    Get-NetIPAddress -InterfaceAlias `$adapter | ? {`$_.AddressFamily -ne "IPv6"} | Remove-NetIPAddress -Confirm:`$false

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Assign $($nic.IPAddress)/$($nic.SubnetCidr) to `$(`$adapter)"   
    New-NetIPAddress –InterfaceAlias `$adapter –IPAddress $($nic.IPAddress) –PrefixLength $($nic.SubnetCidr) -AddressFamily IPv4

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Setting DNS on `$(`$adapter) to $($nic.DNSAddress)"    
    Set-DnsClientServerAddress -InterfaceAlias `$adapter -ResetServerAddresses
    Set-DnsClientServerAddress -InterfaceAlias `$adapter -ServerAddresses @("$($nic.DNSAddress)") 
}


"@
    }

    return $returnString
}

function DeleteItem([string]$path) {

    Write-Host $("Removing " + $path)

    $retry = $true
    
    while (Test-Path -Path $path)
    {      
        try {

            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
        }
        catch {

            if ($_.Exception.HResult -ne "-2147024864") {

                throw $_.Exception
                break
            }

            Start-Sleep -Seconds 3
        }
    }      
}
