function DeployVM {

    param (
        [string]$vmName,

        [string]$vhdxFile,

        [Array]$nics,
   
        [string]$dscFile,

        [PsModule[]]$psModules,

        [string]$organization,

        [Binary[]]$files,

        [int64]$ram,

        [int64]$diskSize,

        [int64]$cores,

        [string]$systemLocale,

        [string]$adminPassword,

        [bool]$online,

        [switch]$enableDSCReboot
    )

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
    
    Write-Host $("Removing " + $path)
    DeleteItem -path $vmVhdDir
    Write-Host "Creating $($vmVhdDir)"
    New-Item -Path $vmVhdDir -ItemType Directory -ErrorAction Stop | Out-Null
        
    # Copy template .vhdx
    $vmVHDPath = [System.IO.Path]::Combine($vmVhdDir, $vmName + ".vhdx")
    Write-Host "Copying $($vhdxFile) to $($vmVHDPath)"
    Copy-Item -Path $vhdxFile -Destination $vmVHDPath -Force -ErrorAction Stop | Out-Null

    # Resize .vhdx
    Write-Host "Expanding $($vmVHDPath) to $($diskSize / 1GB)GB"
    Resize-VHD -Path $vmVHDPath -SizeBytes $diskSize -ErrorAction Stop
        
    # Temporarily disable Bitlocker force on data drives
    $bitlockerKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE"
    $isFveEnabled = (Get-ItemPropertyValue -Path $bitlockerKeyPath -Name FDVDenyWriteAccess -ErrorAction SilentlyContinue) -eq 1
    if ($isFveEnabled) {
        SetItemProperty -path $bitlockerKeyPath -name FDVDenyWriteAccess -type "DWord" -value 0
    }

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

    $encryptedPasswordBytes = [System.Text.Encoding]::Unicode.GetBytes("$($adminPassword)AdministratorPassword")
    $encryptedPassword = [System.Convert]::ToBase64String($encryptedPasswordBytes)

    # Generate Answerfile and copy to .vhdx
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
                    <Value>$encryptedPassword</Value>
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

    Write-Host "Copying unattended file"
    New-Item -Path $(Join-Path -Path ($drive.Root) -ChildPath Windows\Panther) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    $answerFile | Out-File -FilePath $(Join-Path -Path ($drive.Root) -ChildPath Windows\Panther\Unattend.xml) -Force
        
    # Copy DSC .mof file to .vhdx
    if ($dscFile) { 
        $dscFileTarget = Join-Path -Path ($drive.Root) -ChildPath '\Windows\System32\Configuration\Pending.mof'
        Write-Host "Copying DSC configuration $($dscFile) to $($dscFileTarget))"
        Copy-Item -Path $dscFile -Destination $dscFileTarget -ErrorAction Stop            
    }

    # Copy modules to .vhdx
    Write-Host "Copying modules"
    $psModules | ? { $null -ne $_ } | % {
        $moduleSpec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
            ModuleName      = $_.Name
            RequiredVersion = $_.RequiredVersion.ToString()
        })
        $localModule = Get-Module -ListAvailable -FullyQualifiedName $moduleSpec | select -First 1
        if ($null -eq $localModule) {
            Write-Host "Module `"$($_.Name)`" was not found!" -ForegroundColor Red
            continue
        }
        
        $moduleSourceDir = $null
        foreach ($modulePath in ($env:PSModulePath -split ";")) {
            if ($null -eq $moduleSourceDir -and $localModule.Path.ToUpper().Contains($modulePath.ToUpper())) {
                $moduleRelativePath = $localModule.Path.ToUpper().Replace($modulePath.ToUpper() + "\", "")
                $moduleFolderName = $localModule.Path.Substring($modulePath.Length + 1, $moduleRelativePath.IndexOf("\"))
                $moduleSourceDir = [System.IO.Path]::Combine($modulePath, $moduleFolderName)
            }
        }
        if ([String]::IsNullOrWhiteSpace($moduleSourceDir)) {
            Write-Host "Module `"$($_.Name)`" was not found!"
            continue
        }

        $destination = [System.IO.Path]::Combine($drive.Root, "Program Files\WindowsPowerShell\Modules", $moduleFolderName)
        Write-Host "Copying `"$($moduleSourceDir)`" to `"$($destination)`""
        Copy-Item -Path $moduleSourceDir `
            -Destination $destination `
            -Recurse -Force -ErrorAction Stop | Out-Null
    }

    # Copy files to .vhdx
    Write-Host "Copying files"   
    $files | ? { $null -ne $_ } | % {
        Write-Host "Copying $($_.Source) to $($_.Destination.Replace($_.Destination.Split("\")[0], $drive.Name + ":" ))"
        Copy-Item -Path $($_.Source) `
            -Destination $($_.Destination.Replace($_.Destination.Split("\")[0], $drive.Name + ":" )) `
            -Force -Recurse -ErrorAction Stop  | Out-Null
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

    # Reenable Bitlocker data drive protection
    if ($isFveEnabled) {
        SetItemProperty -path $bitlockerKeyPath -name FDVDenyWriteAccess -type "DWord" -value 1
    }

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
            
    return $vm
}