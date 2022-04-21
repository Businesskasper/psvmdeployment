# Build a base image

You need at least one sysprepped VHDX with an installed operating system to serve as a base for our VMs.
You can either build a base image yourself using [sysprep](https://docs.microsoft.com/de-de/windows-hardware/manufacture/desktop/sysprep--system-preparation--overview), or you can use [buildBaseImage.ps1](../sources/Images/buildBaseImage.ps1). 

The script will 
- Build a bootable .VHDX with the ISOs OS preinstalled (but not yet configured)
- Get the latest cumulative update and apply it to the virtual drive
- Enable Net Framework 3.5 (since it's still required by many apps and products)
- Shrink the virtual hard disk to its absolute minimum size using (sdelete)[] and (Optimize-VHD)[]

After you downloaded your prefered ISO (e.g. Windows Server 2019) place the file in sources/Images and invoke the build script:
``.\buildBaseImage.ps1 -isoPath 'c:\hyper-v\psvmdeployment\sources\Images\server_2019.iso' -Product 'Windows Server' -SKU 'Standard (Desktop Experience)' -Version 2019``

As a result, the script will place the generated .VHDX file inside the same folder.