[CmdletBinding(DefaultParametersetName='None')] 
param(
    [Parameter(Mandatory=$true)]
    [string]$isoPath = 'C:\Hyper-V\psvmdeployment\sources\Images\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso',

    [Parameter(Mandatory=$true)]
    [ValidateSet('Standard', 'Standard Desktop')]
    [string]$SKU = 'Standard Desktop',

    [Parameter(ParameterSetName="Update")]
    [Switch]$InstallLatestCU,

    [Parameter(ParameterSetName="Update", Mandatory=$true)]
    [ValidateSet('Windows Server', 'Windows 10')]
    [string]$Product = 'Windows Server',

    [Parameter(ParameterSetName="Update", Mandatory=$true)]
    [string]$Version = '22H2'  
)

if (-not [String]::IsNullOrWhitespace($PSScriptRoot)) {
    $scriptRoot = $PSScriptRoot
}
elseif ($psISE) {
    $scriptRoot = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") {
        $scriptRoot = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $scriptRoot = $MyInvocation.MyCommand.Definition | Split-Path -Parent
    }
}

. $scriptRoot\functions.ps1

$isoDir = $isoPath | Split-Path -Parent

$workingDir = "$($isoDir)\$([guid]::NewGuid())"
Write-Host "Prepare working directory in `"$($workingDir)`""
md $workingDir -ea 0 | Out-Null

# Temporarily disable forced data drive encryption
$forcedEncryptionKey = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE"
$isForcedEncryptionEnabled = (Get-ItemPropertyValue -Path $forcedEncryptionKey -Name "FDVDenyWriteAccess") -eq 1
if ($isForcedEncryptionEnabled) {
    SetItemProperty -path $forcedEncryptionKey -name "FDVDenyWriteAccess" -type DWORD -value 0
}

Write-Host "Download sdelete"
$sdeleteDir = "$($workingDir)\sdelete"
$sdeletePath = DownloadSDelete -installDir $sdeleteDir

if ($InstallLatestCU.IsPresent) {
    if ($null -eq (Get-Module -Name kbupdate -ListAvailable)) {
        Write-Host "Install kbupdate module"
        Install-Module kbupdate -ErrorAction Stop -Force
    }
    Write-Host "Load kbupdate module"
    Import-Module kbupdate

    #Bug in kbupdate module
    Write-Host "Get latest cumulative update"
    $latestUpdate = GetLatestUpdate -Product $Product -Version $Version
    Write-Host "Download `"$($latestUpdate.kb)`""
    $updatePath = Get-KbUpdate -Name $latestUpdate.kb | ? { $_.Title -eq $latestUpdate.title} | Save-KbUpdate -Path $workingDir | select -ExpandProperty FullName
}


Write-Host "Mount ISO"
if (-not (Test-Path -Path $isoPath)) {
    Write-Error -Message "$($isoPath) not found"
}
$before = Get-PSDrive -PSProvider FileSystem
$isoMount = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -Access ReadOnly -PassThru
$after = Get-PSDrive -PSProvider FileSystem
$isoDriveLetter = Compare-Object -ReferenceObject $before -DifferenceObject $after | select -ExpandProperty InputObject | select -ExpandProperty Root

Write-Host "Create VHDX"
$isoLength = (Get-Item -Path $isoPath | select -ExpandProperty Length) / 1GB
$vhdxInitialSize = ([Math]::Round($isoLength, 0) * 3) * 1GB

$vhdxPath = ([System.IO.Path]::Combine($workingDir, (Split-Path -Path $isoPath -Leaf).Replace(".iso", ".vhdx")))
if (Test-Path -Path $vhdxPath) {
    Remove-Item -Path $vhdxPath -Force
}

$vhdx = New-VHD -Dynamic -Path $vhdxPath -SizeBytes $vhdxInitialSize  |
Mount-VHD -Passthru |
Initialize-Disk -PassThru -PartitionStyle GPT

Write-Host "Create Partitions"
$systemPartition = $vhdx | New-Partition -Size 200MB -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
$systemPartition | Format-Volume -FileSystem FAT32 -Force | Out-Null
$systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
$systemPartition | Add-PartitionAccessPath -AssignDriveLetter
$systemPartition = $systemPartition | Get-Partition
$systemDrive = $systemPartition.AccessPaths[0].trimend("\").replace("\?", "??")

$vhdx | New-Partition -Size 128MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' | out-null

$osPartition = $vhdx | New-Partition -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
$osPartition | Format-Volume -FileSystem NTFS -Force | Out-Null
$osPartition | Add-PartitionAccessPath -AssignDriveLetter
$osPartition = $osPartition | Get-Partition
$windowsDrive = $osPartition.AccessPaths[0].substring(0, 2)

Write-Host "Apply WIM to VHDX"
$wimPath = [System.IO.Path]::Combine($isoDriveLetter, "sources", "install.wim")
$imageIndex = GetImageIndex -imagePath $wimPath -sku $SKU
Expand-WindowsImage -ImagePath $wimPath -ApplyPath "$($osPartition.DriveLetter):" -Index $imageIndex | Out-Null

Write-Host "Make .vhdx bootable"
$bcdBootArgs = @(
    "$($windowsDrive)\Windows", # Path to the \Windows on the VHDX
    "/s $systemDrive", # Specifies the volume letter of the drive to create the \BOOT folder on.
    "/v", # Enabled verbose logging.
    "/f UEFI"                   # ÜFI
)

Start-Process -FilePath "C:\windows\system32\bcdboot.exe" -ArgumentList $bcdBootArgs -Wait | out-null

Write-Host "Add .Net Framework 3.5"
Enable-WindowsOptionalFeature -FeatureName NetFx3 -Path "$($osPartition.DriveLetter):"  -Source ([System.IO.Path]::Combine($isoDriveLetter, "sources", "sxs"))  -All -NoRestart | Out-Null

# Hier
if (-not ([String]::IsNullOrWhitespace($updatePath))) {
    Write-Host "Apply latest patch"
    Add-WindowsPackage -PackagePath $updatePath -Path "$($osPartition.DriveLetter):" -PreventPending -LogPath "$($workingDir)\dism.log" -LogLevel Debug | Out-Null
}

Write-Host "Zero and clean free space"
Start-Process -FilePath $sdeletePath -ArgumentList @("-q", "-s", "-c", $windowsDrive) -Wait -PassThru | Out-Null
Start-Process -FilePath $sdeletePath -ArgumentList @("-q", "-s", "-z", $windowsDrive) -Wait -PassThru | Out-Null

Write-Host "Remove drive letter from $($systemPartition.AccessPaths[0])"
$systemPartition | Remove-PartitionAccessPath -AccessPath $systemPartition.AccessPaths[0]

Write-Host "Unmount ISO and VHDX"
Dismount-DiskImage -ImagePath $isoPath -StorageType ISO | Out-Null
Dismount-VHD -Path $vhdxPath | Out-Null


#Optimize .vhdx -> Needs to be remounted in read-only mode
Write-Host "Optimize VHDX"
Mount-VHD -Path $vhdxPath -ReadOnly
Optimize-VHD -Path $vhdxPath -Mode Full
Resize-VHD -Path $vhdxPath -ToMinimumSize
Dismount-VHD -Path $vhdxPath

Write-Host "Cleanup"
# Reenable forced data drive encryption
if ($isForcedEncryptionEnabled) {
    SetItemProperty -path $forcedEncryptionKey -name "FDVDenyWriteAccess" -type DWORD -value 1
}
Move-Item -Path $vhdxPath -Destination $isoDir -Force -Confirm:$false
Remove-Item -Path $workingDir -Force -Recurse -Confirm:$false