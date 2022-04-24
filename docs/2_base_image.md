# Build a base image

At least one [sysprepped](https://docs.microsoft.com/de-de/windows-hardware/manufacture/desktop/sysprep--system-preparation--overview) VHDX with an installed but not configured operating system is required as base the virtual machines.
This process can be automated by invoking [buildBaseImage.ps1](../ps/buildBaseImage.ps1).

The script will 
- Build a bootable VHDX with the ISOs OS preinstalled (but not yet configured).
- (Optionally) Get the latest cumulative update and apply it to the virtual drive.
- Enable Net Framework 3.5 (since it's still required by many apps and products).
- Shrink the virtual hard disk to its absolute minimum size using [sdelete](https://docs.microsoft.com/en-us/sysinternals/downloads/sdelete) and [Optimize-VHD](https://docs.microsoft.com/en-us/powershell/module/hyper-v/optimize-vhd?view=windowsserver2022-ps).
- Place the resulting VHDX in the same directory as the provided ISO. The file may then be moved to [.\sources\Images](./sources/Images).

Example without installing the latest cumulative update:
``.\ps\buildBaseImage.ps1 -isoPath 'c:\hyper-v\psvmdeployment\sources\Images\server_2019.iso' -SKU 'Standard (Desktop Experience)'``

Example including installing the latest cumulative update:
``.\ps\buildBaseImage.ps1 -isoPath 'c:\hyper-v\psvmdeployment\sources\Images\server_2019.iso' -SKU 'Standard (Desktop Experience)' -InstallLatestCU -Product 'Windows Server' -Version 2019``