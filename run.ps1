if ($psISE) {
    $global:root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {
    if ($profile -match "VSCode") { 
        $global:root = $psEditor.GetEditorContext().CurrentFile.Path | Split-Path -Parent
    }
    else {
        $global:root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
    }
}

# Load all classes, functions and role / application definitions
. $global:root\ps\classes.ps1
. $global:root\ps\functions.ps1
. $global:root\ps\roles.ps1

# Load and compile the DSC node definition and playbook
Write-Host "Creating DSC configuration files"
$configData = . $global:root\nodeDefinition.ps1
. $global:root\playbook.ps1

# Create configuration files for each node
$configDir = Join-Path -Path $global:root -ChildPath "Configuration"
New-Item -Path $configDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
DeleteItem -path "$configDir\*.*"
[array]$dscFiles = VMPlaybook -ConfigurationData $configData -OutputPath $configDir

# Deploy nodes
$logJobs = @()
foreach ($node in $configData.AllNodes) {
    $existingNode = Get-VM -Name $($node.NodeName) -ErrorAction SilentlyContinue
    if ($null -ne $existingNode) {  
        Write-Host "$($node.NodeName) ist schon vorhanden. Überpringe.."
        continue
    }

    Write-Host "Deploying $($node.NodeName)"        
        
    # Create NICs if necessary
    $node.NICS | ? { $_ -ne $null } | % { 
        EnsureVMNic -name $_.SwitchName -type $_.SwitchType -nic $_.NIC
    }

    # Create and start vm
    $files = @()
    $node.Roles | % { $files += $_.GetFiles() }
    $node.Applications | % { $files += $_.SourcePath }
    $vm = DeployVM -vmName $node.NodeName `
        -vhdxFile $node.VhdxPath `
        -organization $node.DomainName `
        -dscFile ($dscFiles | ? { $_.BaseName -eq $node.NodeName } | select -first 1 -expandProperty FullName) `
        -enableDSCReboot `
        -files $files `
        -ram $node.RAM `
        -diskSize $node.DiskSize `
        -cores $node.Cores `
        -systemLocale $node.SystemLocale `
        -nics $node.NICS `
        -online ($node.Online -eq $true) `
        -adminPassword $node.LocalCredentials.GetNetworkCredential().Password `
        -psModules $node.Roles.DscModules

    Start-VM -VM $vm | Out-Null

    # Query the DSC event log of the node
    $logJobs += ShowVMLog -vmName $node.NodeName -cred $node.LocalCredentials
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