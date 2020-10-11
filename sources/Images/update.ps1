param(

    [string]$ISO = 'C:\temp\en_windows_server_2019_updated_may_2020_x64_dvd_5651846f.iso',

    [ValidateSet('Windows Server', 'Windows 10')]
    [string]$Product = 'Windows Server',

    [ValidateSet('Standard', 'Datacenter', 'Standard (Desktop Experience)')]
    [string]$SKU = 'Standard',

    [string]$Version = '2019'
)

if ($psISE) {

    $global:root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $global:root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

# Prepare working directory
$workingDir =  ([System.IO.Path]::Combine($global:root, [guid]::NewGuid()))
md $workingDir -ea 0

# Load kbupdate module
if ((Get-Module -Name kbupdate -ListAvailable) -eq $null) {

    Install-Module kbupdate -ErrorAction Stop
}

Import-Module kbupdate

function GetLatestUpdate ([string]$Product, [string]$Version, [DateTime]$Month = [DateTime]::Now, [int]$RoundKey = 0) {

    if ($RoundKey -ge 4) {

        throw [Exception]::new("Keine Updates in den letzten vier Monaten gefunden")
    }

    $_month = $Month.ToString('yyyy-MM')

    Write-Host "Searching for $($_month)"

    $updateCatalog = Invoke-WebRequest -Uri "https://www.catalog.update.microsoft.com/Search.aspx?q=$($_month)%20$($Version)" 

    $table = $updateCatalog.ParsedHtml.getElementById('tableContainer').firstChild.firstChild

    foreach ($item in $table.childNodes) {


        if ($item.innerHTML -like "*$($_month) Cumulative Update for $($Product)*$($Version) for x64-based Systems (KB*") {

            $matches = [regex]::Matches($item.innerHTML, "KB(\d+)")
            return $matches[0].Value
        }
    }

    return GetLatestUpdate -Product $Product -Version $Version -Month ([DateTime]$Month).AddMonths(-1) -RoundKey ($RoundKey + 1)
}


#Get latest Update
$latestUpdate = GetLatestUpdate -Product $product -Version $version
$updatePath = Get-KbUpdate -Name $latestUpdate | ? {$_.Title -like "*Cumulative Update for $($product)*$($version) for x64-based Systems (K*"} | Save-KbUpdate -Path $workingDir | select -ExpandProperty FullName


#Mount iso
if (-not (Test-Path -Path $ISO)) {

    Write-Error -Message "$($ISO) not found"
}

$before = Get-PSDrive -PSProvider FileSystem
$isoMount = Mount-DiskImage -ImagePath $ISO -StorageType ISO -Access ReadOnly -PassThru
$after = Get-PSDrive -PSProvider FileSystem 
$isoDriveLetter = Compare-Object -ReferenceObject $before -DifferenceObject $after | select -ExpandProperty InputObject | select -ExpandProperty Root


#Create new vhdx
$isoLength = (Get-Item -Path $ISO | select -ExpandProperty Length) / 1GB
$vhdxInitialSize = ([Math]::Round($isoLength, 0) * 3) * 1GB

if (Test-Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx")) {

    Remove-Item -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") -Force
}

$vhdx = New-VHD -Dynamic -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") -SizeBytes $vhdxInitialSize  | 
        Mount-VHD -Passthru | 
        Initialize-Disk -PassThru -PartitionStyle GPT

$systemPartition = $vhdx | New-Partition -Size 200MB -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
$systemPartition | Format-Volume -FileSystem FAT32 -Force
$systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
$systemPartition | Add-PartitionAccessPath -AssignDriveLetter

$reservedPartition = $vhdx | New-Partition -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'

$osPartition = $vhdx | New-Partition -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
$osVolume = $osPartition | Format-Volume -FileSystem NTFS -Force

$osPartition = $osPartition | Add-PartitionAccessPath -AssignDriveLetter -PassThru | Get-Partition
$windowsDrive = $(Get-Partition -Volume $osVolume).AccessPaths[0].substring(0,2)

$systemPartition = $systemPartition | Get-Partition
$systemDrive = $systemPartition.AccessPaths[0].trimend("\").replace("\?", "??")



#Apply .wim file to .vhdx
$imageIndex = Get-WindowsImage -ImagePath ([System.IO.Path]::Combine($isoDriveLetter, "sources", "install.wim")) | ? {$_.ImageName -like "*$($SKU)"} | select -ExpandProperty ImageIndex
Expand-WindowsImage -ImagePath ([System.IO.Path]::Combine($isoDriveLetter, "sources", "install.wim")) -ApplyPath "$($osPartition.DriveLetter):" -Index $imageIndex


#Make .vhdx bootable
$bcdBootArgs = @(
    "$($windowsDrive)\Windows", # Path to the \Windows on the VHD
    "/s $systemDrive",          # Specifies the volume letter of the drive to create the \BOOT folder on.
    "/v",                       # Enabled verbose logging.
    "/f UEFI"                   # ÜFI
)

Start-Process -FilePath "C:\windows\system32\bcdboot.exe" -ArgumentList $bcdBootArgs -PassThru -Wait 


#Add .net
Enable-WindowsOptionalFeature -FeatureName NetFx3 -Path "$($osPartition.DriveLetter):"  -Source ([System.IO.Path]::Combine($isoDriveLetter, "sources", "sxs"))  -All -NoRestart

#Patch
Add-WindowsPackage -PackagePath $updatePath -Path "$($osPartition.DriveLetter):" -PreventPending


#Unmount and cleanup
$systemPartition | Remove-PartitionAccessPath -AccessPath $systemPartition.AccessPaths[0]

#Zeroing free space
Start-Process -FilePath C:\tools\sdelete\sdelete64.exe -ArgumentList @("-q", "-s", "-c", $windowsDrive) -Wait -PassThru
#Cleaning free space
Start-Process -FilePath C:\tools\sdelete\sdelete64.exe -ArgumentList @("-q", "-s", "-z", $windowsDrive) -Wait -PassThru

Dismount-DiskImage -ImagePath $ISO -StorageType ISO
Dismount-VHD -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") 


#Optimize .vhdx -> Needs to be remounted in read-only mode
Mount-VHD -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") -ReadOnly
Optimize-VHD -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") -Mode Full
Resize-VHD -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") -ToMinimumSize 
Dismount-VHD -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") 

Move-Item -Path ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $ISO -Leaf).Split(".")[0]) + ".vhdx") -Destination $global:root -Force -Confirm:$false

Remove-Item -Path $workingDir -Force -Recurse -Confirm:$false