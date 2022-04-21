# Prerequisites

You can setup your machine by invoking [ps/setup.ps1](../ps/setup.ps1).
The script will take following actions:
1. Enables Hyper-V (if it's not already enabled)
2. Enables TLS 1.0 and 1.1 since they are required by PowerShellGet
3. Installs NuGet
4. Installs PowerShellGet
5. Registers PSGallery as default and trusted PowerShellGet Provider