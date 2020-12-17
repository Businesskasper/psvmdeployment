if ($psISE) {

    $global:root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $global:root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}

# Load all classes, functions and role / application definitions
. $global:root\ps\classes.ps1
. $global:root\ps\functions.ps1
. $global:root\ps\roles.ps1

# Load and compile the DSC node definition and runbook
Write-Host "Creating DSC configuration files"
$configData = . $global:root\nodeDefinition.ps1
. $global:root\runbook.ps1

# Create configuration files for each node
$configDir = Join-Path -Path $global:root -ChildPath "Configuration"
New-Item -Path $configDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Path "$configDir\*.*" -ErrorAction SilentlyContinue
[array]$dscFiles = VMRunbook -ConfigurationData $configData -OutputPath $configDir

# Deploy the nodes
$logJobs = @()
foreach ($node in $configData.AllNodes) {

    if (!(Get-VM -Name $($node.NodeName) -ErrorAction SilentlyContinue)) {  
        
        Write-Host "Deploying $($node.NodeName)"        
        
        # Create NICs if necessary
        $node.NICS | ? {$_ -ne $null} | % { 
            
            New-VMNic -name $_.SwitchName -type $_.SwitchType -nic $_.NIC
        }

        # Deploy the VM
        $files = @()
        $node.Roles | % { $files += $_.GetFiles()}
        $node.Applications | % { $files += $_.SourcePath }
        Deploy-VM   -vmName $node.NodeName `
                    -vhdxFile $node.VhdxPath `
                    -organization $node.DomainName `
                    -dscFile $dscFiles.Where( {$_.BaseName -eq $node.NodeName} ).FullName `
                    -enableDSCReboot `
                    -files $files `
                    -ram $node.RAM `
                    -diskSize $node.DiskSize `
                    -cores $node.Cores `
                    -systemLocale $node.SystemLocale `
                    -nics $node.NICS `
                    -online $node.Online `
                    -psModules $node.Roles.DscModules

        # Query the DSC event log of the node
        $logJobs += Show-VMLog -vmName $node.NodeName -cred $node.LocalCredentials
    }
    else {

        Write-Host "$($node.NodeName) ist schon vorhanden. Überpringe.."
    }
}


# You can enable this part to close powershell once all VMs are deployed
<#
if ($MyInvocation.Line -like "*&*") {

    $null = Read-Host -Prompt 'Enter drücken ('

    if ($logJobs) {

        Hide-Console

        $ready = $false

        do {
            $logJobs | % {

                if (!($_.IsCompleted)) {

                    $ready = $true
                    Start-Sleep 5
                }
            }
        }
        until ($ready)

        Stop-Process $PID
    }
}
#>