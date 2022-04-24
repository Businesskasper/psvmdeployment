# Prerequisites

You can setup your machine by invoking [ps/setup.ps1](../ps/setup.ps1).
The script will take following actions:
1. Enable Hyper-V (if it's not already enabled)
2. Enable TLS 1.0 and 1.1 since they are required by PowerShellGet
3. Install or update NuGet
4. Install or update PowerShellGet
5. Register the PSGallery as the default and trusted PowerShellGet provider