function EnsureVMNic ([string]$name, [Microsoft.HyperV.PowerShell.VMSwitchType]$type, [string]$nic) {
    
    try {
        Import-Module Hyper-V -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Host "Could not load Hyper-V module!" -ForegroundColor Red
        throw $_.Exception
    }

    if ($null -eq (Get-VMSwitch -Name $name -SwitchType $type -ErrorAction SilentlyContinue)) {
        Write-Host "Creating virtual switch $($name)"

        if ($type -eq [Microsoft.HyperV.PowerShell.VMSwitchType]::External -and $nic -ne $null) {
            New-VMSwitch -Name $name -NetAdapterName $nic 
        }
        else {
            New-VMSwitch -Name $name -SwitchType $type | Out-Null
        }
    }
}